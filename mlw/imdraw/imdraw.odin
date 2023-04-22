package mlw_imdraw

import "mlw:gpu"
import "mlw:core"
import "mlw:media/image"
import "mlw:math"
import "core:slice"
import "core:math/linalg"
import "core:fmt"


/*
    Initialization/Teardown
*/

// It is distinct from gpu.Shader because you need to make sure that imdraw.create_shader is paired with imdraw.destroy_shader (as opposed to the gpu alternatives)
Shader :: distinct gpu.Shader

ATLAS_UNIFORM_NAME :: "imdraw_Atlas"

init :: proc() {
    err: Maybe(string)
    if _default_shader, err = _create_default_shader(); err != nil {
        fmt.printf("Shader Error: %v\n", err.(string))
    }
    _input_buffers.buffers[0], _input_buffers.index = _create_imdraw_buffers()
}

teardown :: proc() {
    delete(_pipelines)
}


/*
    State Changes
*/

set_current_texture :: proc(texture: gpu.Texture) {
    if texture != _current_textures.textures[.Fragment][0] do _flush() // This could work no?
    _current_textures.textures[.Fragment][0] = texture
    _current_textures_info[.Fragment][0] = gpu.texture_info(texture)
    gpu.apply_input_textures(_current_textures)
}

/*
    Rendering
*/

// Note(Dragos): This is a bit goofy for now. I think the renderer could defer everything at the end via draw commands, but this is simple for now
begin :: proc(camera: math.Camera, shader := _default_shader) {
    _buf_idx = 0
    pipeline, pipeline_found := _pipelines[shader]
    assert(pipeline_found, "Invalid shader. Did you create it with imdraw.create_shader?")
    gpu.apply_pipeline(pipeline)
    gpu.apply_input_buffers(_input_buffers)
    _uniforms.modelview, _uniforms.projection = math.camera_to_vp_matrices(camera)
    gpu.apply_uniforms_raw(.Vertex, 0, &_uniforms, size_of(_uniforms))
}

end :: proc() {
    _flush()
}


sprite_size :: proc(position: math.Vec2f, size: math.Size2f, tex_rect: math.Recti, color := math.FRGBA_WHITE) {
    _push_quad({position, auto_cast size}, tex_rect, color)
}


sprite_scale :: proc(position: math.Vec2f, scale: math.Scale2f, tex_rect: math.Recti, color := math.FRGBA_WHITE) {
    tex_size_f := math.Vec2f{cast(f32)tex_rect.size.x, cast(f32)tex_rect.size.y}
    _push_quad({position, tex_size_f * auto_cast scale}, tex_rect, color)
}

sprite :: proc {
    sprite_size,
    sprite_scale,
}


/*
    Asset Creation
*/


// Note(Dragos): This should be separated in _from_file, _from_image, _from_bytes
create_texture :: proc(path: string) -> (texture: gpu.Texture) {
    info: gpu.Texture_Info
    info.type = .Texture2D
    info.format = .RGBA8
    info.min_filter = .Nearest
    info.mag_filter = .Nearest
    info.generate_mipmap = false
    img, err := image.load_from_file(path)
    if err != nil {
        fmt.printf("create_sprite_texture error: %v\n", err)
        return 0
    }
    defer image.delete_image(img)
    assert(img.channels == 4, "Only 4 channels textures are supported atm. Just load a png.")
    info.size.xy = {img.width, img.height}
    info.data = slice.to_bytes(img.rgba_pixels)
    return gpu.create_texture(info)
}

create_shader :: proc(frag_info: gpu.Shader_Stage_Info) -> (shader: Shader, err: Maybe(string)) {
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
    vert_info.uniform_blocks[0].uniforms[0].name = "imdraw_ModelView"
    vert_info.uniform_blocks[0].uniforms[0].type = .mat4f32
    vert_info.uniform_blocks[0].uniforms[1].name = "imdraw_Projection"
    vert_info.uniform_blocks[0].uniforms[1].type = .mat4f32
    
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
    _pipelines[auto_cast gpu_shader] = _create_imdraw_pipeline(auto_cast gpu_shader)

    return auto_cast gpu_shader, nil
}

destroy_shader :: proc(shader: Shader) {
    pipeline, found := _pipelines[shader]
    assert(found, "Shader not found. Did you create it with imdraw.create_shader?")
    gpu.destroy_pipeline(pipeline)
    delete_key(&_pipelines, shader)
    gpu.destroy_shader(auto_cast shader)
}