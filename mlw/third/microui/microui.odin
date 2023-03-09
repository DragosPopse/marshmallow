/*
    microui backend implementation for gpu and platform packages
*/
package mmlow_third_microui

import "../../core"
import "../../math" 
import "../../gpu"
import "../../platform"
import mu "vendor:microui"
import "core:slice"
import "core:fmt"
import linalg "core:math/linalg"

Vertex :: struct {
    pos: math.Vec2f,
    col: math.Colorf,
    tex: math.Vec2f,
}

Vertex_Uniforms :: struct {
    modelview: math.Mat4f,
    projection: math.Mat4f,
}

_state := struct {
    mu_ctx: mu.Context,
	log_buf: [1<<16]byte,
	log_buf_len: int,
	log_buf_updated: bool,
	bg: mu.Color,
	atlas_texture: gpu.Texture,
} {
    bg = {90, 95, 100, 255},
}

BUFFER_SIZE :: 16384
_buf_idx := 0
_vertices: [BUFFER_SIZE * 4]Vertex
_indices: [BUFFER_SIZE * 6]u32


// gpu data
_pipeline: gpu.Pipeline
_shader: gpu.Shader
_uniforms: Vertex_Uniforms
_vert_buf, _ind_buf: gpu.Buffer
_input_textures: gpu.Input_Textures
_input_buffers: gpu.Input_Buffers
_atlas_texture: gpu.Texture

_push_quad :: proc(dst, src: mu.Rect, color: mu.Color) {
    vert_idx := _buf_idx * 4
    index_idx := _buf_idx * 6
    element_idx := _buf_idx * 4
    _buf_idx += 1

    x := cast(f32)src.x / mu.DEFAULT_ATLAS_WIDTH
    y := cast(f32)src.x / mu.DEFAULT_ATLAS_HEIGHT
    w := cast(f32)src.w / mu.DEFAULT_ATLAS_WIDTH
    h := cast(f32)src.h / mu.DEFAULT_ATLAS_HEIGHT

    _vertices[vert_idx + 0].tex = {x, y}
    _vertices[vert_idx + 1].tex = {x + w, y}
    _vertices[vert_idx + 2].tex = {x, y + h}
    _vertices[vert_idx + 3].tex = {x + w, y + h}

    _vertices[vert_idx + 0].pos = {f32(dst.x), f32(dst.y)}
    _vertices[vert_idx + 1].pos = {f32(dst.x + dst.w), f32(y)}
    _vertices[vert_idx + 2].pos = {f32(dst.x), f32(dst.y + dst.h)}
    _vertices[vert_idx + 3].pos = {f32(dst.x + dst.w), f32(dst.y + dst.h)}

    _vertices[vert_idx + 0].col = math.to_colorf(math.Colorb{color.r, color.g, color.b, color.a})
    _vertices[vert_idx + 1].col = math.to_colorf(math.Colorb{color.r, color.g, color.b, color.a})
    _vertices[vert_idx + 2].col = math.to_colorf(math.Colorb{color.r, color.g, color.b, color.a})
    _vertices[vert_idx + 3].col = math.to_colorf(math.Colorb{color.r, color.g, color.b, color.a})

    _indices[index_idx + 0] = u32(element_idx + 0)
    _indices[index_idx + 1] = u32(element_idx + 1)
    _indices[index_idx + 2] = u32(element_idx + 0)
    _indices[index_idx + 3] = u32(element_idx + 0)
    _indices[index_idx + 4] = u32(element_idx + 0)
    _indices[index_idx + 5] = u32(element_idx + 0)
}





_create_microui_shader :: proc() -> (shader: gpu.Shader, err: Maybe(string)) {
    vert_info: gpu.Shader_Stage_Info
    vert: gpu.Shader_Stage
    vert_info.src = #load("microui.vert.glsl", string)
    vert_info.type = .Vertex

    
    vert_info.uniform_blocks[0].size = size_of(Vertex_Uniforms)
    vert_info.uniform_blocks[0].uniforms[0].name = "modelview"
    vert_info.uniform_blocks[0].uniforms[0].type = .mat4f32
    vert_info.uniform_blocks[0].uniforms[1].name = "projection"
    vert_info.uniform_blocks[0].uniforms[1].type = .mat4f32
    
    if vert, err = gpu.create_shader_stage(vert_info); err != nil {
        return 0, err
    }
    defer gpu.destroy_shader_stage(vert)

    frag_info: gpu.Shader_Stage_Info
    frag: gpu.Shader_Stage
    frag_info.src = #load("microui.frag.glsl", string)
    frag_info.type = .Fragment

    frag_info.textures[0].name = "atlas"
    frag_info.textures[0].type = .Texture2D

    if frag, err = gpu.create_shader_stage(frag_info); err != nil {
        return 0, err
    }
    defer gpu.destroy_shader_stage(frag)

    shader_info: gpu.Shader_Info
    shader_info.stages[.Vertex] = vert
    shader_info.stages[.Fragment] = frag

    if shader, err = gpu.create_shader(shader_info, false); err != nil {
        return 0, err
    }

    return shader, nil
}

_create_microui_pipeline :: proc(shader: gpu.Shader) -> (pipeline: gpu.Pipeline) {
    info: gpu.Pipeline_Info
    blend: core.Blend_State
    blend.rgb.src_factor = .Src_Alpha
    blend.rgb.dst_factor = .One_Minus_Src_Alpha
    blend.alpha = blend.rgb
    info.color.blend = blend
    info.shader = shader
    info.index_type = .u32 
    info.primitive_type = .Triangles
    info.polygon_mode = .Fill

    depth: core.Depth_State
    info.depth = depth

    info.layout = core.layout_from_structs([]core.Struct_Layout_Info{
        0 = {Vertex, .Per_Vertex},
    })

    return gpu.create_pipeline(info)
}

_create_microui_buffers :: proc() -> (vertex_buffer, index_buffer: gpu.Buffer) {
    vert_info, index_info: gpu.Buffer_Info

    vert_info.type = .Vertex
    vert_info.usage_hint = .Stream
    vert_info.size = len(_vertices) * size_of(Vertex)

    index_info.type = .Index
    index_info.usage_hint = .Stream
    index_info.size = len(_indices) * size_of(u32)

    return gpu.create_buffer(vert_info), gpu.create_buffer(index_info)
}

_create_atlas_texture :: proc() -> (gpu.Texture) {
    info: gpu.Texture_Info
    info.format = .RGBA8
    info.type = .Texture2D
    info.min_filter = .Nearest
    info.mag_filter = .Nearest

    info.size.xy = {mu.DEFAULT_ATLAS_WIDTH, mu.DEFAULT_ATLAS_HEIGHT}
    pixels := make([][4]u8, mu.DEFAULT_ATLAS_WIDTH * mu.DEFAULT_ATLAS_HEIGHT, context.temp_allocator)
	for alpha, i in mu.default_atlas_alpha {
		pixels[i].rgb = 0xff
		pixels[i].a   = alpha
	}
    info.data = slice.to_bytes(pixels)
    
    return gpu.create_texture(info)
}

init :: proc() {
    mu.init(&_state.mu_ctx)
    _state.mu_ctx.text_width, _state.mu_ctx.text_height = mu.default_atlas_text_width, mu.default_atlas_text_height
    _vert_buf, _ind_buf = _create_microui_buffers()
    _atlas_texture = _create_atlas_texture()
    _uniforms.modelview = math.Mat4f(1)
    // Todo(Dragos): Make a way to get width and height of the viewport inside gpu
    
    _input_textures.textures[.Fragment][0] = _atlas_texture

    _input_buffers.buffers[0] = _vert_buf
    _input_buffers.index = _ind_buf

    shader_err: Maybe(string)
    if _shader, shader_err = _create_microui_shader(); shader_err != nil {
        fmt.printf("SHADER_ERR: %s\n", shader_err.(string))
        return
    }
    _pipeline = _create_microui_pipeline(_shader)
}

process_platform_event :: proc(event: platform.Event) {

}

// Render the data
_flush :: proc() {
    if (_buf_idx == 0) do return 
    _uniforms.projection = linalg.matrix_ortho3d_f32(0, cast(f32)_viewport_width, 0, cast(f32)_viewport_height, 0.1, 100)
    gpu.apply_uniforms_raw(.Vertex, 0, &_uniforms, size_of(_uniforms))
    vertices := _vertices[:_buf_idx * 4]
    indices := _indices[:_buf_idx * 6]
    gpu.buffer_data(_vert_buf, slice.to_bytes(vertices))
    gpu.buffer_data(_ind_buf, slice.to_bytes(indices))
    gpu.apply_input_buffers(_input_buffers)
    gpu.apply_input_textures(_input_textures)
    gpu.draw(0, _buf_idx * 6, 1)
    _buf_idx = 0
}

_viewport_width, _viewport_height: int

render :: proc(ctx: ^mu.Context, viewport_width, viewport_height: int) {
    commands: ^mu.Command
    _viewport_width, _viewport_height = viewport_width, viewport_height
    gpu.apply_pipeline(_pipeline)
    for variant in mu.next_command_iterator(ctx, &commands) {
        switch cmd in variant {
            case ^mu.Command_Text: {
                _draw_text(cmd.str, cmd.pos, cmd.color)
            }

            case ^mu.Command_Rect: {
                _draw_rect(cmd.rect, cmd.color)
            }

            case ^mu.Command_Icon: {
                _draw_icon(cast(int)cmd.id, cmd.rect, cmd.color)
            }

            case ^mu.Command_Clip: {
                fmt.printf("Clip command not implemented\n") // TODO(Dragos): Needs gpu implementation
            }

            case ^mu.Command_Jump: {
                unreachable()
            }
        }
    }

    _flush()
}

_draw_text :: proc(text: string, pos: mu.Vec2, color: mu.Color) {
    dst := mu.Rect{pos.x, pos.y, 0, 0}
    for c in text {
        if (c & 0xc0) == 0x80 do continue // not sure what this is, but it's in the sample
        chr := int(c) if c < 127 else 127
        src := mu.default_atlas[mu.DEFAULT_ATLAS_FONT + chr]
        dst.w = src.w
        dst.h = src.h
        _push_quad(dst, src, color)
        dst.x += dst.w
    }
}

_draw_rect :: proc(rect: mu.Rect, color: mu.Color) {
    _push_quad(rect, mu.default_atlas[mu.DEFAULT_ATLAS_WHITE], color)
}

_draw_icon :: proc(id: int, rect: mu.Rect, color: mu.Color) {
    src := mu.default_atlas[id]
    x := rect.x + (rect.w - src.w) / 2
    y := rect.y + (rect.h - src.h) / 2
    _push_quad({x, y, src.w, src.h}, src, color)
}

