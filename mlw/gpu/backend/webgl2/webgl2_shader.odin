package mmlow_gpu_backend_webgl2

import gl "vendor:wasm/WebGL"
import "../../../core"
import "../../../math"
import "core:strings"
import "core:fmt"
import "core:math/linalg/glsl"

import glcache "../webglcached"

_SHADER_STAGE_TYPE_CONV := [core.Shader_Stage_Type]gl.Enum {
    .Vertex = gl.VERTEX_SHADER,
    .Fragment = gl.FRAGMENT_SHADER,
}

_UNIFORM_SIZES := [core.Uniform_Type]int {
    .i32 = size_of(i32),
    .u32 = size_of(u32),
    .f32 = size_of(f32),
    .vec2f32 = size_of(math.Vec2f),
    .vec3f32 = size_of(math.Vec3f),
    .vec4f32 = size_of(math.Vec4f),
    .mat3f32 = size_of(math.Mat3f),
    .mat4f32 = size_of(math.Mat4f),
}

WebGL2_Uniform_Block :: struct {
    size: int,
    uniform_count: int,
    uniforms: [core.MAX_UNIFORM_BLOCK_ELEMENTS]WebGL2_Uniform,
}

WebGL2_Uniform :: struct {
    name: string,
    location: i32,
    type: core.Uniform_Type,
    count: i32,
    offset: uintptr,
}

WebGL2_Shader_Texture :: struct {
    name: string,
    location: i32,
    target: gl.Enum,
}

// Note(Dragos): This data is for the WebGL2_Shader. It will still be valid when the stage is deleted
WebGL2_Shader_Stage_Info :: struct {
    uniform_blocks_count: int,
    textures_count: int,
    uniform_blocks: [core.MAX_UNIFORM_BLOCKS]WebGL2_Uniform_Block,
    textures: [core.MAX_SHADERSTAGE_TEXTURES]WebGL2_Shader_Texture,
}

WebGL2_Shader_Stage :: struct {
    id: core.Shader_Stage,
    handle: gl.Shader,
    info: WebGL2_Shader_Stage_Info,
}

WebGL2_Shader :: struct {
    id: core.Shader,
    program: gl.Program,
    stages: [core.Shader_Stage_Type]Maybe(WebGL2_Shader_Stage_Info),
}

_shaders: map[core.Shader]WebGL2_Shader
_shader_stages: map[core.Shader_Stage]WebGL2_Shader_Stage


create_shader_stage :: proc(desc: core.Shader_Stage_Info) -> (stage: core.Shader_Stage, temp_error: Maybe(string)) {
    csrc: cstring
    osrc: string
    length: i32
    stageType := _SHADER_STAGE_TYPE_CONV[desc.type]
    switch src in desc.src {
        case []u8: {
            osrc = strings.string_from_ptr(raw_data(src), len(src))
            csrc = strings.unsafe_string_to_cstring(osrc)
            length = cast(i32)len(osrc)
        }

        case string: {
            csrc = strings.unsafe_string_to_cstring(src)
            length = cast(i32)len(src)
        }
    }
    sources := []string{osrc}
    shader := gl.CreateShader(stageType)
    gl.ShaderSource(shader, sources)
    gl.CompileShader(shader)
    
    success: i32 
    log: [512]u8
    success = gl.GetShaderiv(shader, gl.COMPILE_STATUS)
    if success == 0 {
        logLength: i32
        gl.GetShaderInfoLog(shader, log[:])
        logstr := strings.string_from_ptr(&log[0], cast(int)logLength)
        gl.DeleteShader(shader)
        return 0, fmt.tprint(logstr)
    }

    gl_stage: WebGL2_Shader_Stage
    gl_stage.id = core.new_shader_stage_id()
    gl_stage.handle = shader
    
    // Info of the stage for later linking
    gl_stage.info = {}
    for block, i in desc.uniform_blocks {
        if block.size == 0 {
            break
        }
        gl_stage.info.uniform_blocks_count += 1
        block_info := &gl_stage.info.uniform_blocks[i]
        block_info.size = block.size
        current_size: int = 0
        uniform_count: int = 0
        // Note(Dragos): This is not a healthy loop 
        for uniform, i in block.uniforms do if current_size < block.size {
            block_info.uniform_count += 1
            type_size := _UNIFORM_SIZES[uniform.type]
            uniform_info := &block_info.uniforms[i]
            uniform_info.count = cast(i32)uniform.array_count if uniform.array_count > 1 else 1
            uniform_info.name = uniform.name
            uniform_info.type = uniform.type
            uniform_info.offset = cast(uintptr)current_size
            current_size += type_size * cast(int)uniform_info.count
        }
        fmt.assertf(current_size == block.size, "Block size mismatch. Got %v, expected %v.", current_size, block.size)
    }

    for texture, i in desc.textures do if texture.type != .Invalid {
        gl_stage.info.textures_count += 1
        shader_texture := &gl_stage.info.textures[i]
        shader_texture.name = texture.name
        shader_texture.target = _TEXTURE_TARGET_CONV[texture.type]
    } else do break
    

    stage = gl_stage.id
    _shader_stages[stage] = gl_stage
    return
}

destroy_shader_stage :: proc(stage: core.Shader_Stage) {
    assert(stage != 0 && stage in _shader_stages, "Invalid shader stage ID.")
    gl_stage := &_shader_stages[stage]
    gl.DeleteShader(gl_stage.handle)
    core.delete_shader_stage_id(stage)
    delete_key(&_shader_stages, stage)
}

create_shader :: proc(desc: core.Shader_Info, destroy_stages_on_success: bool) -> (shader: core.Shader, temp_error: Maybe(string)) {
    program := gl.CreateProgram()
    gl_shader: WebGL2_Shader
    for stage, type in desc.stages {
        if s, ok := stage.?; ok {
            gl_stage := _shader_stages[s]
            gl_shader.stages[type] = gl_stage.info
            gl.AttachShader(program, gl_stage.handle)
        }
    }
    gl.LinkProgram(program)

    success: i32 
    log: [512]u8 
    success = gl.GetProgramParameter(program, gl.LINK_STATUS)
    
    if success == 0 {
        logLength: i32 
        gl.GetProgramInfoLog(program, log[:])
        logstr := strings.string_from_ptr(&log[0], cast(int)logLength)
        gl.DeleteProgram(program)
        return 0, fmt.tprintf("%s", logstr)
    }
    
    shader = core.new_shader_id()
    gl_shader.id = shader
    gl_shader.program = program
    last_program := glcache.UseProgram(program) 
    current_tex_unit := i32(0)
    for stage, type in gl_shader.stages {
        if stage_info, ok := stage.?; ok {
            for block_i := 0; block_i < stage_info.uniform_blocks_count; block_i += 1 {
                block := &stage_info.uniform_blocks[block_i]
                for uniform_i := 0; uniform_i < block.uniform_count; uniform_i += 1 {
                    uniform := &block.uniforms[uniform_i]
                    uniform.location = gl.GetUniformLocation(program, uniform.name)
                    assert(uniform.location != -1, "Cannot find uniform location.")
                } 
            }

            for texture_i := 0; texture_i < stage_info.textures_count; texture_i += 1 {
                tex := &stage_info.textures[texture_i]
                tex.location = gl.GetUniformLocation(program, tex.name)
                gl.Uniform1i(tex.location, current_tex_unit)
                current_tex_unit += 1
            }
            gl_shader.stages[type] = stage_info
        }
    }
    glcache.UseProgram(last_program)

    _shaders[shader] = gl_shader

    if destroy_stages_on_success {
        for stage in desc.stages {
            if s, ok := stage.?; ok do destroy_shader_stage(s)
        }
    }

    return
}

destroy_shader :: proc(shader: core.Shader) {
    assert(shader != 0 && shader in _shaders, "Attempting to destroy an invalid shader ID.")
    glShader := &_shaders[shader]
    for k, pipeline in &_pipelines {
        if pipeline.shader == glShader do pipeline.shader = nil
    }
    gl.DeleteProgram(glShader.program)
    core.delete_shader_id(shader)
    delete_key(&_shaders, shader)
}

apply_uniforms_raw :: proc(stage: core.Shader_Stage_Type, block_index: int, data: rawptr, size: int) {
    pipeline := &_current_pipeline
    shader := _current_pipeline.shader
    gl_stage, stage_found := &shader.stages[stage].?

    assert(stage_found, "Stage not present in the current pipeline shader.")
    assert(block_index < gl_stage.uniform_blocks_count)

    block := &gl_stage.uniform_blocks[block_index]
    assert(block.size == size, "Size mismatch for uniform block.")
    for uniform_i := 0; uniform_i < block.uniform_count; uniform_i += 1 {
        uniform := &block.uniforms[uniform_i]
        assert(uniform.count > 0, "Uniform count cannot be 0.")
        addr := cast(rawptr)(uintptr(data) + uniform.offset)
        /*
        switch uniform.type {
            case .i32: gl.Uniform1iv(uniform.location, uniform.count, cast([^]i32)addr)
            case .u32: gl.Uniform1uiv(uniform.location, uniform.count, cast([^]u32)addr) 
            case .f32: gl.Uniform1fv(uniform.location, uniform.count, cast([^]f32)addr)
            case .vec2f32: gl.Uniform2fv(uniform.location, uniform.count, cast([^]f32)addr)
            case .vec3f32: gl.Uniform3fv(uniform.location, uniform.count, cast([^]f32)addr)
            case .vec4f32: gl.Uniform4fv(uniform.location, uniform.count, cast([^]f32)addr)
            case .mat3f32: gl.UniformMatrix3fv(uniform.location, uniform.count, false, cast([^]f32)addr)
            case .mat4f32: gl.UniformMatrix4fv(uniform.location, uniform.count, false, cast([^]f32)addr)          
        }
        */
        switch uniform.type {
            case .i32: {
                val := cast(^i32)(addr)
                gl.Uniform1iv(uniform.location, val^)
            }
            case .u32: {
                val := cast(^u32)(addr)
                gl.Uniform1uiv(uniform.location, val^) 
            }
            case .f32: {
                val := cast(^f32)(addr)
                gl.Uniform1fv(uniform.location, val^)
            }
            case .vec2f32: {
                val := cast(^glsl.vec2)(addr)
                gl.Uniform2fv(uniform.location, val^)
            }
            case .vec3f32: {
                val := cast(^glsl.vec3)(addr)
                gl.Uniform3fv(uniform.location, val^)
            }
            case .vec4f32: {
                val := cast(^glsl.vec4)(addr)
                gl.Uniform4fv(uniform.location, val^)
            }
            case .mat3f32: {
                val := cast(^glsl.mat3)(addr)
                gl.UniformMatrix3fv(uniform.location, val^)
            }
            case .mat4f32: {
                val := cast(^glsl.mat4)(addr)
                gl.UniformMatrix4fv(uniform.location, val^)
            }
        }
    }
}