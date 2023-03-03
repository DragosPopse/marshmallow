package mmlow_gpu

import "../core"

// Data Types 
Texture :: core.Texture
Shader :: core.Shader
Shader_Stage :: core.Shader_Stage
Pipeline :: core.Pipeline 
Buffer :: core.Buffer

//Descriptors
Texture_Info :: core.Texture_Info
Shader_Info :: core.Shader_Info
Shader_Stage_Info :: core.Shader_Stage_Info
Pipeline_Info :: core.Pipeline_Info
Buffer_Info :: core.Buffer_Info

Cull_Mode :: core.Cull_Mode
Shader_Stage_Type :: core.Shader_Stage_Type

Layout_Info :: core.Layout_Info 
Attr_Layout_Info :: core.Attr_Layout_Info
Buffer_Layout_Info :: core.Buffer_Layout_Info
Attr_Format :: core.Attr_Format
Input_Buffers :: core.Input_Buffers
Input_Textures :: core.Input_Textures

Pass :: core.Render_Pass
Pass_Info :: core.Render_Pass_Info
Attachment_Info :: core.Attachment_Info
Pass_Action :: core.Render_Pass_Action

// Helpful for backend interface errors

// Initialization
Backend_Init :: #type proc()
Backend_Teardown :: #type proc()


// Pipeline
Backend_Create_Pipeline :: #type proc(desc: Pipeline_Info) -> Pipeline
Backend_Destroy_Pipeline :: #type proc(pipeline: Pipeline)
Backend_Apply_Pipeline :: #type proc(pipeline: Pipeline)
Backend_Apply_Input_Buffers :: #type proc(buffers: Input_Buffers)
Backend_Apply_Input_Textures :: #type proc(textures: Input_Textures)
//

// Pass
Backend_Create_Pass :: #type proc(info: Pass_Info) -> Pass
Backend_Destroy_Pass :: #type proc(pass: Pass)
Backend_Begin_Pass :: #type proc(pass: Pass, action: Pass_Action)
Backend_Begin_Default_Pass :: #type proc(action: Pass_Action, width, height: int)
Backend_End_Pass :: #type proc()
//

// Note(Dragos): Maybe these are not needed?
Backend_Create_Shader_Stage :: #type proc(desc: Shader_Stage_Info) -> (stage: Shader_Stage, temp_error: Maybe(string))
Backend_Destroy_Shader_Stage :: #type proc(stage: Shader_Stage)
//

// Shader
Backend_Create_Shader :: #type proc(desc: Shader_Info, destroy_stages_on_success: bool) -> (shader: Shader, temp_error: Maybe(string))
Backend_Destroy_Shader :: #type proc(shader: Shader)
Backend_Apply_Uniforms_Raw :: #type proc(stage: Shader_Stage_Type, block_index: int, data: rawptr, size: int)
//

// Buffer
Backend_Create_Buffer :: #type proc(desc: Buffer_Info) -> Buffer
Backend_Destroy_Buffer :: #type proc(buffer: Buffer)
Backend_Buffer_Data :: #type proc(buffer: Buffer, data: []byte)
//

// Texture
Backend_Create_Texture :: #type proc(desc: Texture_Info) -> Texture
Backend_Destroy_Texture :: #type proc(texture: Texture)
//

// Drawing
Backend_Draw :: #type proc(base_elem: int, elem_count: int, instance_count: int)

Backend_Default_Graphics_Info :: #type proc() -> core.Graphics_Info