package mlw_imdraw

import "../gpu"
import "../core"
import "../media/image"
import "../math"
import "core:slice"
import "core:math/linalg"
import "core:fmt"

// Note(Dragos): This seems good enough to push to package mlw:imdraw

Vertex :: struct {
    pos: math.Vec2f,
    col: math.Color4f,
    tex: math.Vec2f,
}

Vertex_Uniforms :: struct {
    imdraw_MVP: math.Mat4f,
}


BUFFER_SIZE :: 16384
_buf_idx := 0
_vertices: [BUFFER_SIZE * 4]Vertex
_indices: [BUFFER_SIZE * 6]u32


// gpu data
_pipelines: map[Shader]gpu.Pipeline
_default_shader: Shader
_uniforms: Vertex_Uniforms
_input_buffers: gpu.Input_Buffers

// Note(Dragos): Hope we won't need this in the future
_viewport_width, _viewport_height: int

_current_textures: gpu.Input_Textures
_current_textures_info: [core.Shader_Stage_Type][core.MAX_SHADERSTAGE_TEXTURES]gpu.Texture_Info



_push_quad :: proc(dst: math.Rectf, src: math.Recti, color: math.Color4f, origin: math.Vec2f) {
    dst := math.rect_align_with_origin(dst, origin)

    vert_idx := _buf_idx * 4
    index_idx := _buf_idx * 6
    element_idx := _buf_idx * 4
    _buf_idx += 1
    
    tinfo := &_current_textures_info[.Fragment][0]

    texture_width := cast(f32)tinfo.size.x
    texture_height := cast(f32)tinfo.size.y

    x := cast(f32)src.x / texture_width
    y := cast(f32)src.y / texture_height
    w := cast(f32)src.size.x / texture_width
    h := cast(f32)src.size.y / texture_height

    
    _vertices[vert_idx + 0].tex = {x, y}
    _vertices[vert_idx + 1].tex = {x + w, y}
    _vertices[vert_idx + 2].tex = {x, y + h}
    _vertices[vert_idx + 3].tex = {x + w, y + h}

    _vertices[vert_idx + 0].pos = {f32(dst.x), f32(dst.y)}
    _vertices[vert_idx + 1].pos = {f32(dst.x + dst.size.x), f32(dst.y)}
    _vertices[vert_idx + 2].pos = {f32(dst.x), f32(dst.y + dst.size.y)}
    _vertices[vert_idx + 3].pos = {f32(dst.x + dst.size.x), f32(dst.y + dst.size.y)}
    
    _vertices[vert_idx + 0].col = color
    _vertices[vert_idx + 1].col = color
    _vertices[vert_idx + 2].col = color
    _vertices[vert_idx + 3].col = color

    _indices[index_idx + 0] = u32(element_idx + 0)
    _indices[index_idx + 1] = u32(element_idx + 1)
    _indices[index_idx + 2] = u32(element_idx + 2)
    _indices[index_idx + 3] = u32(element_idx + 2)
    _indices[index_idx + 4] = u32(element_idx + 3)
    _indices[index_idx + 5] = u32(element_idx + 1)
}


_create_default_shader :: proc() -> (shader: Shader, err: Maybe(string)) {
    frag_info: gpu.Shader_Stage_Info
    frag_info.type = .Fragment  

    when gpu.BACKEND == .glcore3 {
        frag_info.src = #load("shaders/default.frag.glsl", string)
    } else {
        #panic("Only glcore3 supported sorry.")
    }
    
    frag_info.textures[0].name = ATLAS_UNIFORM_NAME
    frag_info.textures[0].type = .Texture2D

    return create_shader(frag_info)
}

_create_imdraw_pipeline :: proc(shader: Shader) -> (pipeline: gpu.Pipeline) {
    info: gpu.Pipeline_Info
    blend: core.Blend_State
    blend.rgb.src_factor = .Src_Alpha
    blend.rgb.dst_factor = .One_Minus_Src_Alpha
    blend.alpha = blend.rgb
    info.color.blend = blend
    info.shader = auto_cast shader
    info.index_type = .u32 
    info.primitive_type = .Triangles
    info.polygon_mode = .Fill


    info.layout = core.layout_from_structs([]core.Struct_Layout_Info{
        0 = {Vertex, .Per_Vertex},
    })

    return gpu.create_pipeline(info)
}

_create_imdraw_buffers :: proc() -> (vertex_buffer, index_buffer: gpu.Buffer) {
    vert_info, index_info: gpu.Buffer_Info

    vert_info.type = .Vertex
    vert_info.usage_hint = .Dynamic
    vert_info.size = len(_vertices) * size_of(Vertex)

    index_info.type = .Index
    index_info.usage_hint = .Dynamic
    index_info.size = len(_indices) * size_of(u32)

    return gpu.create_buffer(vert_info), gpu.create_buffer(index_info)
}


// Render the data
// I don't need all this gpu calls now that i have a being and end, but we'll see
_flush :: proc() {
    if (_buf_idx == 0) do return 
    //_uniforms.projection = linalg.matrix_ortho3d_f32(0, cast(f32)_viewport_width, 0, cast(f32)_viewport_height, 0, 100, false)
    gpu.apply_uniforms_raw(.Vertex, 0, &_uniforms, size_of(_uniforms))
    vertices := _vertices[:_buf_idx * 4]
    indices := _indices[:_buf_idx * 6]
    gpu.buffer_data(_input_buffers.buffers[0], slice.to_bytes(vertices))
    gpu.buffer_data(_input_buffers.index.(gpu.Buffer), slice.to_bytes(indices))
    gpu.apply_input_buffers(_input_buffers)
    gpu.apply_input_textures(_current_textures)
    gpu.draw(0, _buf_idx * 6, 1)
    _buf_idx = 0
}

