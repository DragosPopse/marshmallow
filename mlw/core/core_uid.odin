package mmlow_core 

@(private = "file") _next_buffer_id: Buffer = 1
@(private = "file") _next_texture_id: Texture = 1
@(private = "file") _next_pipeline_id: Pipeline = 1
@(private = "file") _next_shader_stage_id: Shader_Stage = 1
@(private = "file") _next_shader_id: Shader = 1
@(private = "file") _next_pass_id: Pass = 1

new_buffer_id :: proc() -> (uid: Buffer) {
    uid = _next_buffer_id
    _next_buffer_id += 1
    return
}

new_texture_id :: proc() -> (uid: Texture) {
    uid = _next_texture_id
    _next_texture_id += 1
    return
}

new_pipeline_id :: proc() -> (uid: Pipeline) {
    uid = _next_pipeline_id
    _next_pipeline_id += 1
    return
}

new_shader_stage_id :: proc() -> (uid: Shader_Stage) {
    uid = _next_shader_stage_id
    _next_shader_stage_id += 1
    return
}

new_shader_id :: proc() -> (uid: Shader) {
    uid = _next_shader_id
    _next_shader_id += 1
    return
}

new_pass_id :: proc() -> (uid: Pass) {
    uid = _next_pass_id 
    _next_pass_id += 1
    return
}


// Note(Dragos): This has no effect yet, but it's recommended to use these functions
delete_buffer_id :: proc(uid: Buffer) {

}

delete_texture_id :: proc(uid: Texture) {

}

delete_pipeline_id :: proc(uid: Pipeline) {

}

delete_shader_stage_id :: proc(uid: Shader_Stage) {

}

delete_shader_id :: proc(uid: Shader) {

}

delete_pass_id :: proc(uid: Pass) {
    
}