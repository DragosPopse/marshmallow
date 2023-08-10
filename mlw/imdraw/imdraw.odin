package mlw_imdraw

import "../gpu"
import "../core"
import "../media/image"
import "../math"
import "core:slice"
import "core:math/linalg"
import "core:fmt"
import "../math/camera"

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
    start: int,
    parent_length: int, // The length of the view this view is derived from. Used for setting up the element index
    length: int,
    texture_size: [2]int, // Internal use
}

buffer_view_slice :: proc(view: ^Render_Buffer_View) -> #soa []Quad {
    return view.buffer.quads[view.start : view.start + view.length]
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

_state: State

/*
    Initialization/Teardown
*/

// It is distinct from gpu.Shader because you need to make sure that imdraw.create_shader is paired with imdraw.destroy_shader (as opposed to the gpu alternatives)
Shader :: distinct gpu.Shader
Texture :: struct {
    texture: gpu.Texture,
    size: [2]int,
}

ATLAS_UNIFORM_NAME :: "imdraw_Atlas"

init :: proc() {
    state_init(&_state)
}

teardown :: proc() {
    // Todo(Dragos): This is not complete
    delete(_state.pipelines)
}


/*
    State Changes
*/

/*
    Rendering
*/

begin :: proc() {
    using _state
    buffer.next_quad = 0 // Reset render buffer
    resize(&draw_states, 0) // Reset draw states
    resize(&cameras, 0)

     // Push the first state as a default, with an empty bufferv view
    first_state: Internal_Draw_State
    first_state.texture = empty_texture
    first_state.shader = default_shader
    first_state.camera_index = -1
    append(&draw_states, first_state)
}

end :: proc() {
    using _state
    if buffer.next_quad == 0 do return
    for state in &draw_states {
        if state.buffer_view.length == 0 do continue
        pipeline, pipeline_found := pipelines[state.shader]
        assert(pipeline_found, "Unable to find shader.")
        gpu.apply_pipeline(pipeline)
        quads := buffer_view_slice(&state.buffer_view)
        vertices, indices := soa_unzip(quads)
        //fmt.printf("%v %v\n%#v\n", len(vertices), len(slice.to_bytes(vertices[:])), vertices)
        gpu.buffer_data(state.buffer_view.buffer.vertex_buffer, slice.to_bytes(vertices[:]))
        gpu.buffer_data(state.buffer_view.buffer.index_buffer, slice.to_bytes(indices[:]))

        in_buff: gpu.Input_Buffers
        in_buff.buffers[0] = state.buffer_view.buffer.vertex_buffer
        in_buff.index = state.buffer_view.buffer.index_buffer
        gpu.apply_input_buffers(in_buff)
        
        in_tex: gpu.Input_Textures
        in_tex.textures[.Fragment][0] = state.texture.texture
        gpu.apply_input_textures(in_tex)
        
        vert_uniforms: Vertex_Uniforms
        vert_uniforms.imdraw_MVP = _state.cameras[state.camera_index]
        gpu.apply_uniforms_raw(.Vertex, 0, &vert_uniforms, size_of(vert_uniforms))
        
        
        gpu.draw(0, len(indices) * 6, 1)
    }
}

apply_camera :: proc(cam: camera.Camera2D) {
    append(&_state.cameras, camera.to_vp_matrix(cam)) 
    _state.current_camera_index = len(_state.cameras) - 1
}

/*
    Rendering
*/

Render_Flag :: enum {
    Flip_X,
    Flip_Y,
}

Render_Flags :: bit_set[Render_Flag]

sprite :: proc(texture: Texture, tex_rect: math.Recti, dst_rect: math.Rectf, dst_origin: math.Vec2f, rotation: math.Angle = math.Rad(0), color := math.WHITE_4f, flags: Render_Flags = {}) {
    state: Draw_State
    state.camera_index = _state.current_camera_index
    state.shader = _state.default_shader
    state.texture = texture
    view := reserve_buffer(1, state)

    set_quad(&view, 0, dst_rect, tex_rect, color, dst_origin, rotation, flags)
    return // debug
}

quad :: proc(dst: math.Rectf, origin: math.Vec2f = {0, 0}, rotation: math.Angle = math.Rad(0), color := math.WHITE_4f) {
    //using _state
    //_apply_texture(empty_texture, true)
    //_push_quad(dst, {{0, 0}, {1, 1}}, color, origin, rotation)
    state: Draw_State
    state.camera_index = _state.current_camera_index
    state.shader = _state.default_shader
    state.texture = _state.empty_texture
    view := reserve_buffer(1, state)
    set_quad(&view, 0, dst, {{0, 0}, {1, 1}}, color, origin, rotation)
    return // debug
}

line_quad :: proc(dst: math.Rectf, origin: math.Vec2f, line_width: f32, rotation: math.Angle, color := math.WHITE_4f) {
    dst := math.rect_align_with_origin(dst, origin)
    //dst := dst
    

    topleft := dst.pos
    topright := math.Vec2f{dst.pos.x + dst.size.x, dst.pos.y}
    bottomright := math.Vec2f{dst.pos.x + dst.size.x, dst.pos.y + dst.size.y}
    bottomleft := math.Vec2f{dst.pos.x, dst.pos.y + dst.size.y}
    
    
    top, left, right, bottom: math.Rectf
    line_size := math.Vec2f{line_width, dst.size.y}
    
    center := math.rect_center(dst, origin)

    top.size = {dst.size.x, line_width}
    top.pos = topleft
    to := math.rectf_origin_from_world_point(top, center)
    top.pos = topleft + to * top.size
    
    left.size = {line_width, dst.size.y}
    left.pos = topleft
    lo := math.rectf_origin_from_world_point(left, center)
    left.pos = topleft + lo * left.size
    

    bottom.size = {dst.size.x + line_width, line_width}
    bottom.pos = bottomleft
    bo := math.rectf_origin_from_world_point(bottom, center)
    //bo.y = -bo.y
    bottom.pos = bottomleft + bo * bottom.size
    

    right.size = {line_width, dst.size.y}
    right.pos = topright
    ro := math.rectf_origin_from_world_point(right, center)
    //ro.x = -ro.x
    right.pos = topright + ro * right.size
    

    quad(top, to, rotation, color)
    quad(left, lo, rotation, color)
    quad(bottom, bo, rotation, color)
    quad(right, ro, rotation, color)
}

line :: proc(begin: math.Vec2f, end: math.Vec2f, width: f32, color := math.WHITE_4f) {
    l := end - begin
    rads := cast(math.Rad)math.atan2(l.y, l.x)
    length := math.length(end - begin)
    //fmt.printf("%v %v\n", math.rad_to_deg(rads), slope)
    dst: math.Rectf
    dst.pos = begin
    dst.size.x = length
    dst.size.y = width
    quad(dst, {0, 0}, rads, color)
}

/*
    Asset Creation
*/


// Note(Dragos): This should be separated in _from_file, _from_image, _from_bytes
create_texture_from_file :: proc(path: string) -> (texture: Texture) {
    info: gpu.Texture_Info
    info.type = .Texture2D
    info.format = .RGBA8
    info.min_filter = .Nearest
    info.mag_filter = .Nearest
    info.generate_mipmap = false
    img, err := image.load_from_file(path)
    if err != nil {
        fmt.printf("create_sprite_texture error: %v\n", err)
        return {}
    }
    defer image.delete_image(img)
    assert(img.channels == 4, "Only 4 channels textures are supported atm. Just load a png.")
    info.size.xy = {img.width, img.height}
    info.data = slice.to_bytes(img.rgba_pixels)

    texture.texture = gpu.create_texture(info)
    texture.size = info.size.xy
    return texture
}

create_shader :: proc(frag_info: gpu.Shader_Stage_Info) -> (shader: Shader, err: Maybe(string)) {
    using _state
    vert_info: gpu.Shader_Stage_Info
    vert: gpu.Shader_Stage
    frag: gpu.Shader_Stage

    // The vertex shader should always stay the same

    vert_info.type = .Vertex

    when gpu.BACKEND == .glcore3 {
        vert_info.src = #load("shaders/imdraw.vert.glsl", string)
    } else {
        #panic("Only glcore3 supported sorry.")
    }
    
    vert_info.uniform_blocks[0].size = size_of(Vertex_Uniforms)
    vert_info.uniform_blocks[0].uniforms[0].name = "imdraw_MVP"
    vert_info.uniform_blocks[0].uniforms[0].type = .mat4f32
    
    if vert, err = gpu.create_shader_stage(vert_info); err != nil {
        return 0, err
    }
    defer gpu.destroy_shader_stage(vert)


    assert(frag_info.type == .Fragment, "Expected a fragment shader stage info for imdraw.create_shader")
    assert(frag_info.textures[0].name == ATLAS_UNIFORM_NAME, "The first texture in the shader must have a specific name. Check imdraw.ATLAS_UNIFORM_NAME")
    assert(frag_info.textures[0].type == .Texture2D, "The first texture in the shader must be a Texture2D")

    if frag, err = gpu.create_shader_stage(frag_info); err != nil {
        return 0, err
    }
    defer gpu.destroy_shader_stage(frag)

    shader_info: gpu.Shader_Info
    shader_info.stages[.Vertex] = vert
    shader_info.stages[.Fragment] = frag

    gpu_shader: gpu.Shader
    if gpu_shader, err = gpu.create_shader(shader_info, false); err != nil {
        return 0, err
    }

    // Create a pipeline for this shader, similar to the rest. Maybe in the future we can do some more changes in here, by specializing Shader_Stage_Info
    pipelines[auto_cast gpu_shader] = _create_imdraw_pipeline(auto_cast gpu_shader)

    return auto_cast gpu_shader, nil
}

destroy_shader :: proc(shader: Shader) {
    using _state
    pipeline, found := pipelines[shader]
    assert(found, "Shader not found. Did you create it with imdraw.create_shader?")
    gpu.destroy_pipeline(pipeline)
    delete_key(&pipelines, shader)
    gpu.destroy_shader(auto_cast shader)
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

    view.start = view.buffer.next_quad
    //#no_bounds_check view.quads = view.buffer.quads[view.buffer.next_quad : view.buffer.next_quad + n_quads] 
    view.length = n_quads
    view.buffer.next_quad += n_quads

    if new_camera || new_shader || new_texture { // Create a new state and a buffer view
        ids.buffer_view = view
        append(&draw_states, ids) 
    } else { // Merge the last state with this one and expand the last state buffer view
        view.parent_length = curr_state.buffer_view.length
        //#no_bounds_check curr_state.buffer_view.quads = curr_state.buffer_view.buffer.quads[curr_state.buffer_view.start : curr_state.buffer_view.start + len(curr_state.buffer_view.quads) + len(view.quads)]
        curr_state.buffer_view.length += view.length
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




// Todo(Dragos): remove #no_bounds_check in many places in favor of referencing things
set_quad :: proc(view: ^Render_Buffer_View, idx: int, dst: math.Rectf, src: math.Recti, color: math.Color4f, origin: math.Vec2f, rotation: math.Angle, flags := Render_Flags{}) #no_bounds_check {
    assert(idx >= 0 && idx < view.length, "Index out of bounds")
    dst := math.rect_align_with_origin(dst, origin)

    if .Flip_X in flags {
        dst.size.x = -dst.size.x
        dst.pos.x -= dst.size.x
    }
    if .Flip_Y in flags {
        dst.size.y = -dst.size.y
        dst.pos.y -= dst.size.y
    }

    element_idx := (view.parent_length + idx) * 4 // should this be idx + 1??
    quad := &view.buffer.quads[view.start + idx]
    texture_width := cast(f32)view.texture_size.x
    texture_height := cast(f32)view.texture_size.y

    x := cast(f32)src.x / texture_width
    y := cast(f32)src.y / texture_height
    w := cast(f32)src.size.x / texture_width
    h := cast(f32)src.size.y / texture_height

    quad.vert[0].tex = {x, y}
    quad.vert[1].tex = {x + w, y}
    quad.vert[2].tex = {x, y + h}
    quad.vert[3].tex = {x + w, y + h}

    rads := cast(f32)math.angle_rad(rotation)
    quad.vert[0].pos = {f32(dst.x), f32(dst.y), rads}
    quad.vert[1].pos = {f32(dst.x + dst.size.x), f32(dst.y), rads}
    quad.vert[2].pos = {f32(dst.x), f32(dst.y + dst.size.y), rads}
    quad.vert[3].pos = {f32(dst.x + dst.size.x), f32(dst.y + dst.size.y), rads}

    quad.vert[0].col = color
    quad.vert[1].col = color
    quad.vert[2].col = color
    quad.vert[3].col = color

    center := math.rect_center(dst, origin)
    quad.vert[0].center = center
    quad.vert[1].center = center
    quad.vert[2].center = center
    quad.vert[3].center = center

    quad.ind[0] = u32(element_idx + 0)
    quad.ind[1] = u32(element_idx + 1)
    quad.ind[2] = u32(element_idx + 2)
    quad.ind[3] = u32(element_idx + 2)
    quad.ind[4] = u32(element_idx + 3)
    quad.ind[5] = u32(element_idx + 1)
}


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

// Note(Dragos): The pipeline is tied to blend state + shader, which makes dynamic setup quite annoying. This will easily lead to combinatoric explosion
//              We should implement a d3d11 backend, and then change the way we create a pipeline to allow more dynamic changes.
//              Having blend on every call is quite expensive:(
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