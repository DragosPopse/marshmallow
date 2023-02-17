package mmlow_gpu

import "../core"

BACKEND :: core.GPU_BACKEND
BACKEND_FAMILY :: core.GPU_BACKEND_FAMILY
when BACKEND == .glcore3 {
    import backend "backend/glcore3"
} else {
    #panic("Unsupported GPU_BACKEND")
}


// Procedures
init     : Backend_Init     : backend.init
teardown : Backend_Teardown : backend.teardown

create_shader_stage  : Backend_Create_Shader_Stage : backend.create_shader_stage
destroy_shader_stage : Backend_Destroy_Shader_Stage : backend.destroy_shader_stage

create_shader  : Backend_Create_Shader : backend.create_shader
destroy_shader : Backend_Destroy_Shader : backend.destroy_shader

apply_uniforms_raw : Backend_Apply_Uniforms_Raw : backend.apply_uniforms_raw

create_buffer  : Backend_Create_Buffer  : backend.create_buffer
destroy_buffer : Backend_Destroy_Buffer : backend.destroy_buffer
buffer_data : Backend_Buffer_Data : backend.buffer_data
apply_input_buffers : Backend_Apply_Input_Buffers : backend.apply_input_buffers

create_texture  : Backend_Create_Texture : backend.create_texture
destroy_texture : Backend_Destroy_Texture : backend.destroy_texture
apply_input_textures : Backend_Apply_Input_Textures : backend.apply_input_textures

create_pipeline  : Backend_Create_Pipeline : backend.create_pipeline
destroy_pipeline : Backend_Destroy_Pipeline : backend.destroy_pipeline
apply_pipeline : Backend_Apply_Pipeline : backend.apply_pipeline

draw : Backend_Draw : backend.draw

create_graphics_context: Backend_Create_Graphics_Context : backend.create_graphics_context