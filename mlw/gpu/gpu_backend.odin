package mmlow_gpu

import "../core"

BACKEND :: core.GPU_BACKEND
BACKEND_FAMILY :: core.GPU_BACKEND_FAMILY

import "backend/glcore3"
import "backend/webgl2"

when BACKEND == .glcore3 {
    backend :: glcore3
} else when BACKEND == .webgl2 {
    backend :: webgl2
} else {
    #panic("Unsupported GPU_BACKEND")
}

default_pass_action :: core.default_pass_action

// Procedures 
init :: proc() {
    backend.init()
}

teardown :: proc() {
    backend.teardown()
}

create_shader_stage :: proc(info: Shader_Stage_Info) -> (stage: Shader_Stage, err: Maybe(string)) {
    return backend.create_shader_stage(info)
}

destroy_shader_stage :: proc(stage: Shader_Stage) {
    backend.destroy_shader_stage(stage)
}

create_shader :: proc(info: Shader_Info, destroy_stages_on_success: bool) -> (shader: Shader, err: Maybe(string)){
    return backend.create_shader(info, destroy_stages_on_success)
}

destroy_shader :: proc(shader: Shader) {
    backend.destroy_shader(shader)
}

apply_uniforms_raw :: proc(stage: Shader_Stage_Type, block_index: int, data: rawptr, size: int) {
    backend.apply_uniforms_raw(stage, block_index, data, size)
}

create_buffer :: proc(info: Buffer_Info) -> Buffer {
    return backend.create_buffer(info)
}

destroy_buffer :: proc(buffer: Buffer) {
    backend.destroy_buffer(buffer)
}

buffer_data :: proc(buffer: Buffer, data: []byte) {
    backend.buffer_data(buffer, data)
}

apply_input_buffers :: proc(buffers: Input_Buffers) {
    backend.apply_input_buffers(buffers)
}

create_texture :: proc(info: Texture_Info) -> Texture {
    return backend.create_texture(info)
}

destroy_texture :: proc(texture: Texture) {
    backend.destroy_texture(texture)
}

texture_data :: proc(texture: Texture, data: []byte) {
    backend.texture_data(texture, data)
}

texture_info :: proc(texture: Texture) -> Texture_Info {
    return backend.texture_info(texture)
}

apply_input_textures :: proc(textures: Input_Textures) {
    backend.apply_input_textures(textures)
}

create_pass :: proc(info: Pass_Info) -> Pass {
    return backend.create_pass(info)
}

destroy_pass :: proc(pass: Pass) {
    backend.destroy_pass(pass)
}

begin_default_pass :: proc(action: Pass_Action, width, height: int) {
    backend.begin_default_pass(action, width, height)
}

begin_pass :: proc(pass: Pass, action: Pass_Action) {
    backend.begin_pass(pass, action)
}

end_pass :: proc() {
    backend.end_pass()
} 

create_pipeline :: proc(info: Pipeline_Info) -> Pipeline {
    return backend.create_pipeline(info)
}

destroy_pipeline :: proc(pipeline: Pipeline) {
    backend.destroy_pipeline(pipeline)
}

apply_pipeline :: proc(pipeline: Pipeline) {
    backend.apply_pipeline(pipeline)
}

draw :: proc(base_elem, elem_count, instance_count: int) {
    backend.draw(base_elem, elem_count, instance_count)
}

default_graphics_info :: proc() -> core.Graphics_Info {
    return backend.default_graphics_info()
}