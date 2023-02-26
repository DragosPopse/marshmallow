package mmlow_imdraw

import "../core"
import "../math"
import "../gpu"



_draw_list: Command_Buffer

_in_progress: bool

_sprite_pipeline: gpu.Pipeline
_line_pipeline: gpu.Pipeline
_sprite_shader: gpu.Shader

_current_camera: ^math.Camera

create_sprite_pipeline :: proc(shader: gpu.Shader) -> (pipeline: gpu.Pipeline) {
    info: gpu.Pipeline_Info
    blend: core.Blend_State
    blend.rgb.src_factor = .Src_Alpha
    blend.rgb.dst_factor = .One_Minus_Src_Alpha
    blend.alpha = blend.rgb
    info.color.blend = blend
    info.primitive_type = .Triangles
    info.shader = shader
    return gpu.create_pipeline(info)
}

create_line_pipeline :: proc() -> (pipeline: gpu.Pipeline) {
    info: gpu.Pipeline_Info

    return gpu.create_pipeline(info)
}

create_sprite_shader :: proc() -> (shader: gpu.Shader, err: Maybe(string)) {
    vert_info: gpu.Shader_Stage_Info
    vert: gpu.Shader_Stage
    vert_info.src = #load("shaders/sprite_vert.glsl", string)
    vert_info.type = .Vertex

    vert_info.uniform_blocks[0].size = size_of(Sprite_Uniforms)
    vert_info.uniform_blocks[0].uniforms[0].name = "Model"
    vert_info.uniform_blocks[0].uniforms[0].type = .mat4f32
    vert_info.uniform_blocks[0].uniforms[1].name = "Color"
    vert_info.uniform_blocks[0].uniforms[1].type = .vec4f32

    vert_info.uniform_blocks[1].size = size_of(Camera_Uniforms)
    vert_info.uniform_blocks[1].uniforms[0].name = "View"
    vert_info.uniform_blocks[1].uniforms[0].type = .mat4f32
    vert_info.uniform_blocks[1].uniforms[1].name = "Projection"
    vert_info.uniform_blocks[1].uniforms[1].type = .mat4f32

    if vert, err = gpu.create_shader_stage(vert_info); err != nil {
        return 0, err
    }
    defer gpu.destroy_shader_stage(vert)

    frag_info: gpu.Shader_Stage_Info
    frag: gpu.Shader_Stage
    frag_info.src = #load("shaders/sprite_frag.glsl", string)
    frag_info.type = .Fragment
    frag_info.textures[0].name = "Texture"
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


init :: proc() {
    _draw_list = make_command_buffer()
    _sprite_shader, _ = create_sprite_shader() 
    _sprite_pipeline = create_sprite_pipeline(_sprite_shader)
}

teardown :: proc() {
    delete_command_buffer(&_draw_list)
}

begin :: proc() {
    assert(!_in_progress, "Did you forget to call imdraw.end()?")
    clear_command_buffer(&_draw_list)
    _in_progress = true
}

end :: proc() {
    assert(_in_progress, "Did you forget to call imdraw.begin()?")
    _in_progress = false
    _sort_command_buffer(&_draw_list)
    _render_command_buffer(&_draw_list)
}

_sort_command_buffer :: proc(commands: ^Command_Buffer) {

}

_render_command_buffer :: proc(commands: ^Command_Buffer) {
    last_texture: gpu.Texture = 0
    input_textures: gpu.Input_Textures
    last_camera: ^math.Camera
    gpu.apply_pipeline(_sprite_pipeline)
    for sprite in commands.sprites {
        assert(sprite.camera != nil, "Camera not set. Call imdraw.camera(&cam)")
        if last_texture != sprite.texture {
            input_textures.textures[.Fragment][0] = sprite.texture
            gpu.apply_input_textures(input_textures)
        }
        last_texture = sprite.texture

        sprite_uniforms: Sprite_Uniforms
        sprite_uniforms.model = math.transform_to_mat4f(sprite.transform)
        sprite_uniforms.color = sprite.color
        gpu.apply_uniforms_raw(.Vertex, 0, &sprite_uniforms, size_of(sprite_uniforms))
        if last_camera != sprite.camera {
            camera_uniforms: Camera_Uniforms
            camera_uniforms.view, camera_uniforms.projection = math.camera_to_mat4f(_current_camera^)
            gpu.apply_uniforms_raw(.Vertex, 1, &camera_uniforms, size_of(camera_uniforms))
        }
    }
}

camera :: proc(cam: ^math.Camera) {
    _current_camera = cam
}

sprite_vec3 :: proc(texture: gpu.Texture, position: math.Vec3f, rotation: math.Vec3f = {0, 0, 0}, scale: math.Vec3f = {1, 1, 1}, color := math.fWHITE) {
    cmd: Command_Sprite
    cmd.color = color
    cmd.texture = texture
    cmd.transform = {position, rotation, scale}
    cmd.camera = _current_camera
    push_command(&_draw_list, cmd)
}

sprite_transform :: proc(texture: gpu.Texture, transform: math.Transform, color := math.fWHITE) {
    cmd: Command_Sprite
    cmd.color = color
    cmd.texture = texture
    cmd.transform = transform
    cmd.camera = _current_camera
    push_command(&_draw_list, cmd)
}

sprite :: proc {
    sprite_vec3,
    sprite_transform,
}

