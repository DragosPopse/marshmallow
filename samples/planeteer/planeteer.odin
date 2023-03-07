package main

import "core:fmt"
import "core:mem"
import "../../mlw/core"
import "../../mlw/gpu"
import "../../mlw/image"
import "../../mlw/math"
import "../../mlw/platform"
import "core:slice"

create_standard_shader :: proc() -> (shader: gpu.Shader, err: Maybe(string)) {
    vert_info: gpu.Shader_Stage_Info
    vert: gpu.Shader_Stage
    vert_info.src = #load("standard.vert.glsl", string)
    vert_info.type = .Vertex

    if vert, err = gpu.create_shader_stage(vert_info); err != nil {
        return 0, err
    }
    defer gpu.destroy_shader_stage(vert)

    frag_info: gpu.Shader_Stage_Info
    frag: gpu.Shader_Stage
    frag_info.src = #load("standard.frag.glsl", string)
    frag_info.type = .Fragment
    

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

create_standard_pipeline :: proc(shader: gpu.Shader) -> (pipeline: gpu.Pipeline) {
    pipe_info: gpu.Pipeline_Info
    blend: core.Blend_State
    blend.rgb.src_factor = .Src_Alpha
    blend.rgb.dst_factor = .One_Minus_Src_Alpha
    blend.alpha = blend.rgb
    pipe_info.color.blend = blend
    pipe_info.shader = shader
    pipe_info.index_type = .u32 
    pipe_info.primitive_type = .Triangles
    depth: core.Depth_State
    pipe_info.depth = depth // Note(Dragos): not fully implemented

    pipe_info.layout.attrs[0].buffer_index = 0
    pipe_info.layout.attrs[0].format = .vec3f32
    pipe_info.layout.attrs[0].offset = 0
    pipe_info.layout.buffers[0].step = .Per_Vertex
    pipe_info.layout.buffers[0].stride = size_of(math.Vec3f)

    return gpu.create_pipeline(pipe_info)
}

WIDTH, HEIGHT := 600, 600

initialize :: proc() {
    platform_info: platform.Init_Info
    platform_info.window.size = {WIDTH, HEIGHT}
    platform_info.window.title = "Planeteer"
    platform_info.graphics = gpu.default_graphics_info()
    platform.init(platform_info)
    gpu.init()
}

_planet: Planet

main :: proc() {
    initialize()
    shader: gpu.Shader
    shader_err: Maybe(string)
    if shader, shader_err = create_standard_shader(); shader_err != nil {
        fmt.panicf("SHADER_ERR: %s\n", shader_err.(string))
    }
    pipeline := create_standard_pipeline(shader)
    
    init_planet(&_planet, 20)
    construct_planet_mesh(&_planet)
    planet_vertices, planet_indices := merge_planet_meshes(_planet)
    planet_vb: gpu.Buffer
    {
        info: gpu.Buffer_Info
        info.type = .Vertex
        data := slice.to_bytes(planet_vertices)
        info.data = data
        info.size = len(data)
        info.usage_hint = .Dynamic
        planet_vb = gpu.create_buffer(info)
    }
    
    planet_ib: gpu.Buffer
    {
        info: gpu.Buffer_Info
        info.type = .Index
        data := slice.to_bytes(planet_indices)
        info.data = data
        info.size = len(data)
        info.usage_hint = .Dynamic
        planet_ib = gpu.create_buffer(info)
    }

    input_buffers: gpu.Input_Buffers
    input_buffers.buffers[0] = planet_vb
    input_buffers.index = planet_ib 

    pass_action := gpu.default_pass_action()
    pass_action.colors[0].value = math.Colorf{0.012, 0.533, 0.988, 1.0}

    running := true 
    for running {
        for event in platform.poll_event() {
            #partial switch in event {
                case core.Quit_Event: {
                    running = false
                }
            }
        }

        gpu.begin_default_pass(pass_action, WIDTH, HEIGHT)
        gpu.apply_pipeline(pipeline)
        gpu.apply_input_buffers(input_buffers)
        gpu.draw(0, len(planet_indices), 1)
        gpu.end_pass()

        platform.update_window()
    }
}