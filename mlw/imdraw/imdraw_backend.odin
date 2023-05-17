package mlw_imdraw

import "../gpu"
import "../core"
import "../media/image"
import "../math"
import "core:slice"
import "core:math/linalg"
import "core:fmt"

Vertex :: struct {
    pos: math.Vec3f,
    col: math.Color4f,
    tex: math.Vec2f,
    center: math.Vec2f,
}

Quad :: struct {
    vert: [4]Vertex,
    ind: [6]u32,
}

// This can be extended further to allow triangle buffers too. But for now we only support quads.
// The Render_Buffer should be treated as a readonly thing. Make a view if you wanna modify shit.
Render_Buffer :: struct {
    quads: #soa [dynamic]Quad, 
    vertex_buffer, index_buffer: gpu.Buffer,
    next_quad: int,
}

// Note(Dragos): When a new allocation happens mid frame, the view buffers could get invalidated....
// Todo(Dragos): Somehow needs to be fixed. Maybe storing indices in the buffer rather than the #soa quads, and converting to slice on user side.
// We can store indices in the internal Draw State, and keep the view as a #soa slice
Render_Buffer_View :: struct {
    buffer: ^Render_Buffer,
    buffer_index: int,
    subview_index: int,
    quads: #soa []Quad,
    texture_size: [2]int, // Internal use
}

// Todo(Dragos): This one gots to have indices, not a view, otherwise it might get invalidated
// Removing this will increase performance further
Internal_Draw_State :: struct {
    buffer_view: Render_Buffer_View,
    texture: Texture,
    shader: Shader,
    camera_index: int, // This can be made into vertex uniforms directly to avoid some copies
}

Draw_State :: struct {
    texture: Texture,
    shader: Shader,
    camera_index: int,
}


Vertex_Uniforms :: struct {
    imdraw_MVP: math.Mat4f,
}

DEFAULT_BUFFER_SIZE :: 16384 * 4


// We can implement a stack-state API
State :: struct {
    pipelines: map[Shader]gpu.Pipeline,
    buffer: Render_Buffer,
    default_shader: Shader,
    empty_texture: Texture,
    draw_states: [dynamic]Internal_Draw_State,
    cameras: [dynamic]math.Mat4f,
    current_camera_index: int,
}

/*
    Reserve a certain number of quads to be drawn at the end of the frame. its similar to other draw functions, but it will return to you a writable buffer that will be renderer
    
*/
reserve_buffer :: proc(n_quads: int, draw_state: Draw_State) -> (view: Render_Buffer_View) {
    using _state
    #no_bounds_check curr_state := &draw_states[len(draw_states) - 1]

    ids: Internal_Draw_State
    ids.shader = draw_state.shader
    ids.texture = draw_state.texture
    ids.camera_index = draw_state.camera_index 
    
    

    new_shader := ids.shader != curr_state.shader
    new_texture := ids.texture.texture != curr_state.texture.texture
    new_camera := ids.camera_index != curr_state.camera_index // Need to get this check simpler. Maybe make a pointer to the camera mvp?

    view.buffer = &buffer
    view.texture_size.xy = ids.texture.size.xy

    // Resize internal buffer to support the number of required quads
    if buffer.next_quad + n_quads > len(buffer.quads) {
        resize_soa(&buffer.quads, len(buffer.quads) * 2)
    }

    view.buffer_index = view.buffer.next_quad
    #no_bounds_check view.quads = view.buffer.quads[view.buffer.next_quad : view.buffer.next_quad + n_quads] 
    view.buffer.next_quad += n_quads

    if new_camera || new_shader || new_texture { // Create a new state and a buffer view
        ids.buffer_view = view
        append(&draw_states, ids) 
    } else { // Merge the last state with this one and expand the last state buffer view
        view.subview_index = len(curr_state.buffer_view.quads)
        #no_bounds_check curr_state.buffer_view.quads = curr_state.buffer_view.buffer.quads[curr_state.buffer_view.buffer_index : curr_state.buffer_view.buffer_index + len(curr_state.buffer_view.quads) + len(view.quads)]
    }
    
    return view
}


state_init :: proc(state: ^State) {
    err: Maybe(string)
    if state.default_shader, err = _create_default_shader(); err != nil {
        fmt.printf("Imdraw shader error: %s\n", err.(string))
    }
    state.empty_texture = _create_empty_texture()
    state.buffer.vertex_buffer, state.buffer.index_buffer = _create_imdraw_buffers()
    resize_soa(&state.buffer.quads, DEFAULT_BUFFER_SIZE)
}


_state: State

set_quad :: proc(view: ^Render_Buffer_View, idx: int, dst: math.Rectf, src: math.Recti, color: math.Color4f, origin: math.Vec2f, rotation: math.Angle) #no_bounds_check {
    assert(idx >= 0 && idx < len(view.quads), "Index out of bounds")
    dst := math.rect_align_with_origin(dst, origin)

    element_idx := (view.subview_index + idx) * 4 // should this be idx + 1??

    texture_width := cast(f32)view.texture_size.x
    texture_height := cast(f32)view.texture_size.y

    x := cast(f32)src.x / texture_width
    y := cast(f32)src.y / texture_height
    w := cast(f32)src.size.x / texture_width
    h := cast(f32)src.size.y / texture_height

    view.quads[idx].vert[0].tex = {x, y}
    view.quads[idx].vert[1].tex = {x + w, y}
    view.quads[idx].vert[2].tex = {x, y + h}
    view.quads[idx].vert[3].tex = {x + w, y + h}

    rads := cast(f32)math.angle_rad(rotation)
    view.quads[idx].vert[0].pos = {f32(dst.x), f32(dst.y), rads}
    view.quads[idx].vert[1].pos = {f32(dst.x + dst.size.x), f32(dst.y), rads}
    view.quads[idx].vert[2].pos = {f32(dst.x), f32(dst.y + dst.size.y), rads}
    view.quads[idx].vert[3].pos = {f32(dst.x + dst.size.x), f32(dst.y + dst.size.y), rads}

    view.quads[idx].vert[0].col = color
    view.quads[idx].vert[1].col = color
    view.quads[idx].vert[2].col = color
    view.quads[idx].vert[3].col = color

    center := math.rect_center(dst, origin)
    view.quads[idx].vert[0].center = center
    view.quads[idx].vert[1].center = center
    view.quads[idx].vert[2].center = center
    view.quads[idx].vert[3].center = center

    view.quads[idx].ind[0] = u32(element_idx + 0)
    view.quads[idx].ind[1] = u32(element_idx + 1)
    view.quads[idx].ind[2] = u32(element_idx + 2)
    view.quads[idx].ind[3] = u32(element_idx + 2)
    view.quads[idx].ind[4] = u32(element_idx + 3)
    view.quads[idx].ind[5] = u32(element_idx + 1)
}

// Make the buffer an argument to this somehow. We need to be able to multithread this shit
/*
_push_quad :: proc(dst: math.Rectf, src: math.Recti, color: math.Color4f, origin: math.Vec2f, rotation: math.Angle) {
    using _state
    

    //if buf_idx * 4 * size_of(vertices[0]) >= size_of(vertices) do _flush()
    if buffer.next_quad >= len(buffer.quads) do resize_soa(&buffer.quads, len(buffer.quads) * 2)
    
    dst := math.rect_align_with_origin(dst, origin)

    vert_idx := buffer.next_quad
    index_idx := buffer.next_quad
    element_idx := buffer.next_quad * 4
    buffer.next_quad += 1

    texture_width := cast(f32)gs.texture.size.x
    texture_height := cast(f32)gs.texture.size.y

    x := cast(f32)src.x / texture_width
    y := cast(f32)src.y / texture_height
    w := cast(f32)src.size.x / texture_width
    h := cast(f32)src.size.y / texture_height

    
    buffer.quads[vert_idx].vert[0].tex = {x, y}
    buffer.quads[vert_idx].vert[1].tex = {x + w, y}
    buffer.quads[vert_idx].vert[2].tex = {x, y + h}
    buffer.quads[vert_idx].vert[3].tex = {x + w, y + h}

    rads := cast(f32)math.angle_rad(rotation)

    buffer.quads[vert_idx].vert[0].pos = {f32(dst.x), f32(dst.y), rads}
    buffer.quads[vert_idx].vert[1].pos = {f32(dst.x + dst.size.x), f32(dst.y), rads}
    buffer.quads[vert_idx].vert[2].pos = {f32(dst.x), f32(dst.y + dst.size.y), rads}
    buffer.quads[vert_idx].vert[3].pos = {f32(dst.x + dst.size.x), f32(dst.y + dst.size.y), rads}

    buffer.quads[vert_idx].vert[0].col = color
    buffer.quads[vert_idx].vert[1].col = color
    buffer.quads[vert_idx].vert[2].col = color
    buffer.quads[vert_idx].vert[3].col = color

    buffer.quads[index_idx].ind[0] = u32(element_idx + 0)
    buffer.quads[index_idx].ind[1] = u32(element_idx + 1)
    buffer.quads[index_idx].ind[2] = u32(element_idx + 2)
    buffer.quads[index_idx].ind[3] = u32(element_idx + 2)
    buffer.quads[index_idx].ind[4] = u32(element_idx + 3)
    buffer.quads[index_idx].ind[5] = u32(element_idx + 1)

    //center := math.Vec2f((vertices[vert_idx + 0].pos.xy + vertices[vert_idx + 1].pos.xy + vertices[vert_idx + 2].pos.xy + vertices[vert_idx + 3].pos.xy) / 4)
    center := math.rect_center(dst, origin)
    buffer.quads[vert_idx].vert[0].center = center
    buffer.quads[vert_idx].vert[1].center = center
    buffer.quads[vert_idx].vert[2].center = center
    buffer.quads[vert_idx].vert[3].center = center
}
*/

_create_empty_texture :: proc() -> (texture: Texture) {
    info: gpu.Texture_Info
    info.size.xy = {1, 1}
    white := math.WHITE_4b
    info.format = .RGBA8
    info.type = .Texture2D
    info.min_filter = .Nearest
    info.mag_filter = .Nearest
    info.generate_mipmap = false
    info.data = slice.to_bytes(slice.from_ptr(&white, 1))

    texture.texture = gpu.create_texture(info)
    texture.size = info.size.xy
    return 
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
    using _state

    vert_info, index_info: gpu.Buffer_Info

    vert_info.type = .Vertex
    vert_info.usage_hint = .Dynamic
    vert_info.size = DEFAULT_BUFFER_SIZE * 4 * size_of(Vertex)

    index_info.type = .Index
    index_info.usage_hint = .Dynamic
    index_info.size = DEFAULT_BUFFER_SIZE * 6 * size_of(u32)

    return gpu.create_buffer(vert_info), gpu.create_buffer(index_info)
}


// Render the data
// I don't need all this gpu calls now that i have a being and end, but we'll see
// Flush should be removed in favor of adding a new draw state object
/*
_flush :: proc() {
    using _state
    if buffer.next_quad == 0 do return 
    

    gpu.apply_uniforms_raw(.Vertex, 0, &gs.vertex_uniforms, size_of(gs.vertex_uniforms))
    verters, indecers := soa_unzip(buffer.quads[:])
    v_slice := verters[:buffer.next_quad]
    i_slice := indecers[:buffer.next_quad]
    gpu.buffer_data(buffer.vertex_buffer, slice.to_bytes(v_slice))
    gpu.buffer_data(buffer.index_buffer, slice.to_bytes(i_slice))
    input_buffers: gpu.Input_Buffers
    input_buffers.buffers[0] = buffer.vertex_buffer
    input_buffers.index = buffer.index_buffer
    gpu.apply_input_buffers(input_buffers)
    textures: gpu.Input_Textures
    textures.textures[.Fragment][0] = gs.texture.texture
    gpu.apply_input_textures(textures)
    gpu.draw(0, buffer.next_quad * 6, 1)
    buffer.next_quad = 0
}

*/