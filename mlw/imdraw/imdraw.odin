package mlw_imdraw

import "../gpu"
import "../core"
import "../media/image"
import "../math"
import "core:slice"
import "core:math/linalg"
import "core:fmt"


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

// Note(Dragos): This is a bit goofy for now. I think the renderer could defer everything at the end via draw commands, but this is simple for now
begin :: proc() {
    using _state
    _flush() // Maybe not needed.
    _apply_shader(default_shader, true)
}

end :: proc() {
    _flush()
}

apply_camera :: proc(cam: math.Camera) {
    #force_inline _apply_camera(cam, true)
}

apply_shader :: proc(s: Shader) {
    #force_inline _apply_shader(s, false)
}

/*
    Rendering
*/

sprite :: proc(texture: Texture, dst_rect: math.Rectf, dst_origin: math.Vec2f, tex_rect: math.Recti, rotation: math.Angle = math.Rad(0), color := math.WHITE_4f) {
    _apply_texture(texture, true)
    _push_quad(dst_rect, tex_rect, color, dst_origin, rotation)
}

quad :: proc(dst: math.Rectf, origin: math.Vec2f = {0, 0}, rotation: math.Angle = math.Rad(0), color := math.WHITE_4f) {
    using _state
    _apply_texture(empty_texture, true)
    _push_quad(dst, {{0, 0}, {1, 1}}, color, origin, rotation)
}

line_quad :: proc(dst: math.Rectf, origin: math.Vec2f, line_width: f32, rotation: math.Angle, color := math.WHITE_4f) {
    dst := math.rect_align_with_origin(dst, origin)
    center := math.rect_center(dst, {0.5, 0.5})
    
    topleft := dst.pos
    topright := math.Vec2f{dst.pos.x + dst.size.x, dst.pos.y}
    bottomright := math.Vec2f{dst.pos.x + dst.size.x, dst.pos.y + dst.size.y}
    bottomleft := math.Vec2f{dst.pos.x, dst.pos.y + dst.size.y}

    
    top, left, right, bottom: math.Rectf
    line_size := math.Vec2f{line_width, dst.size.y}

    top.size = {dst.size.x, line_width}
    top.pos = topleft

    left.size = {line_width, dst.size.y}
    left.pos = topleft

    right.size = {line_width, dst.size.y}
    right.pos = topright

    bottom.size = {dst.size.x, line_width}
    bottom.pos = bottomleft

    /*
    top = math.rect_align_with_origin(top, origin)
    left = math.rect_align_with_origin(top, origin)
    right = math.rect_align_with_origin(top, origin)
    bottom = math.rect_align_with_origin(top, origin)
    */

    quad(top, math.rect_origin_from_relative_point(top, center - dst.pos), rotation, color)
    //quad(left, math.rect_origin_from_relative_point(left, center - dst.pos), rotation, color)
    //quad(bottom, math.rect_origin_from_relative_point(bottom, center - dst.pos), rotation, color)
    //quad(right, math.rect_origin_from_relative_point(right, center - dst.pos), rotation, color)
    
    //quad(top, origin, rotation, color)
    //quad(left, origin, rotation, color)
    //quad(bottom, origin, rotation, color)
}

line :: proc(begin: math.Vec2f, end: math.Vec2f, width: f32, color := math.WHITE_4f) {
    slope := math.slope(begin, end)
    rads := cast(math.Rad)math.atan(slope)
    length := math.length(end - begin)
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