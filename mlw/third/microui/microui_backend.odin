/*
    microui backend implementation for gpu and platform packages
*/
package mmlow_third_microui

import "../../core"
import "../../math" 
import "../../gpu"
import "../../platform"
import "../../platform/event"
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

// Note(Dragos): Hope we won't need this in the future
_viewport_width, _viewport_height: int

_push_quad :: proc(dst, src: mu.Rect, color: mu.Color) {
    vert_idx := _buf_idx * 4
    index_idx := _buf_idx * 6
    element_idx := _buf_idx * 4
    _buf_idx += 1

    x := cast(f32)src.x / mu.DEFAULT_ATLAS_WIDTH
    y := cast(f32)src.y / mu.DEFAULT_ATLAS_HEIGHT
    w := cast(f32)src.w / mu.DEFAULT_ATLAS_WIDTH
    h := cast(f32)src.h / mu.DEFAULT_ATLAS_HEIGHT

    
    _vertices[vert_idx + 0].tex = {x, y}
    _vertices[vert_idx + 1].tex = {x + w, y}
    _vertices[vert_idx + 2].tex = {x, y + h}
    _vertices[vert_idx + 3].tex = {x + w, y + h}
    
    _vertices[vert_idx + 0].pos = {f32(dst.x), f32(_viewport_width) - f32(dst.y)}
    _vertices[vert_idx + 1].pos = {f32(dst.x + dst.w), f32(_viewport_width) - f32(dst.y)}
    _vertices[vert_idx + 2].pos = {f32(dst.x), f32(_viewport_width) - f32(dst.y + dst.h)}
    _vertices[vert_idx + 3].pos = {f32(dst.x + dst.w), f32(_viewport_width) - f32(dst.y + dst.h)}

    colorf := math.to_colorf(math.Colorb{color.r, color.g, color.b, color.a})
    _vertices[vert_idx + 0].col = colorf
    _vertices[vert_idx + 1].col = colorf
    _vertices[vert_idx + 2].col = colorf
    _vertices[vert_idx + 3].col = colorf

    _indices[index_idx + 0] = u32(element_idx + 0)
    _indices[index_idx + 1] = u32(element_idx + 1)
    _indices[index_idx + 2] = u32(element_idx + 2)
    _indices[index_idx + 3] = u32(element_idx + 2)
    _indices[index_idx + 4] = u32(element_idx + 3)
    _indices[index_idx + 5] = u32(element_idx + 1)
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


    info.layout = core.layout_from_structs([]core.Struct_Layout_Info{
        0 = {Vertex, .Per_Vertex},
    })

    return gpu.create_pipeline(info)
}

_create_microui_buffers :: proc() -> (vertex_buffer, index_buffer: gpu.Buffer) {
    vert_info, index_info: gpu.Buffer_Info

    vert_info.type = .Vertex
    vert_info.usage_hint = .Dynamic
    vert_info.size = len(_vertices) * size_of(Vertex)

    index_info.type = .Index
    index_info.usage_hint = .Dynamic
    index_info.size = len(_indices) * size_of(u32)

    return gpu.create_buffer(vert_info), gpu.create_buffer(index_info)
}

_create_atlas_texture :: proc() -> (gpu.Texture) {
    info: gpu.Texture_Info
    info.type = .Texture2D
    info.min_filter = .Nearest
    info.mag_filter = .Nearest
    info.generate_mipmap = true

    info.size.xy = {mu.DEFAULT_ATLAS_WIDTH, mu.DEFAULT_ATLAS_HEIGHT}
    
    // Is this the problem?!
    info.format = .RGBA8
    pixels := make([][4]u8, mu.DEFAULT_ATLAS_WIDTH * mu.DEFAULT_ATLAS_HEIGHT, context.temp_allocator)
	for alpha, i in mu.default_atlas_alpha {
		pixels[i].rgb = 255
		pixels[i].a   = alpha
	}
    
    /*
    for row := mu.DEFAULT_ATLAS_HEIGHT - 1; row >= 0; row -= 1 {
        for column := 0; column < mu.DEFAULT_ATLAS_WIDTH; column += 1 {
            i := row * mu.DEFAULT_ATLAS_WIDTH + column
            j := (mu.DEFAULT_ATLAS_HEIGHT - 1 - row) * mu.DEFAULT_ATLAS_WIDTH + column
            pixels[i].rgb = 255
            pixels[i].a = mu.default_atlas_alpha[j]
            //fmt.printf("r: %v, c: %v, i: %v, j: %v, a: %v\n", row, column, i, j, (mu.DEFAULT_ATLAS_HEIGHT - 1 - row))
        }
    }*/
    info.data = slice.to_bytes(pixels)
    
    //info.format = .A8
    //info.data = slice.to_bytes(mu.default_atlas_alpha[:])
    return gpu.create_texture(info)
}



_button_map := [event.Mouse_Button]mu.Mouse{
    event.Mouse_Button.Left  =  mu.Mouse.LEFT,
    event.Mouse_Button.Right =  mu.Mouse.RIGHT,
    event.Mouse_Button.Wheel =  mu.Mouse.MIDDLE,
}
  
_key_map := [256]mu.Key{
     cast(int)event.Key.LShift       & 0xff  = mu.Key.SHIFT,
     cast(int)event.Key.RShift       & 0xff  = mu.Key.SHIFT,
     cast(int)event.Key.LControl        & 0xff  = mu.Key.CTRL,
     cast(int)event.Key.RControl        & 0xff  = mu.Key.CTRL,
     cast(int) event.Key.LAlt         & 0xff  = mu.Key.ALT,
     cast(int)event.Key.RAlt         & 0xff  = mu.Key.ALT,
     cast(int)event.Key.Return       & 0xff  = mu.Key.RETURN,
     cast(int)event.Key.Backspace    & 0xff  = mu.Key.BACKSPACE,
  };
  



// Render the data
_flush :: proc() {
    if (_buf_idx == 0) do return 
    _uniforms.projection = linalg.matrix_ortho3d_f32(0, cast(f32)_viewport_width, 0, cast(f32)_viewport_height, 0, 100, false)
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

