package main

import "core:fmt"
import "core:mem"
import "../../mlw/core"
import "../../mlw/gpu"
import "../../mlw/image"
import "../../mlw/math"
import "../../mlw/platform"
import linalg "core:math/linalg"
import "core:slice"
import mu "vendor:microui"
import mu_mlw "../../mlw/third/microui"



Vertex_Uniforms :: struct {
    model, view, projection: math.Mat4f,
}

create_standard_shader :: proc() -> (shader: gpu.Shader, err: Maybe(string)) {
    vert_info: gpu.Shader_Stage_Info
    vert: gpu.Shader_Stage
    vert_info.src = #load("standard.vert.glsl", string)
    vert_info.type = .Vertex

    vert_info.uniform_blocks[0].size = size_of(Vertex_Uniforms)
    vert_info.uniform_blocks[0].uniforms[0].name = "model"
    vert_info.uniform_blocks[0].uniforms[0].type = .mat4f32
    vert_info.uniform_blocks[0].uniforms[1].name = "view"
    vert_info.uniform_blocks[0].uniforms[1].type = .mat4f32
    vert_info.uniform_blocks[0].uniforms[2].name = "projection"
    vert_info.uniform_blocks[0].uniforms[2].type = .mat4f32

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
    //pipe_info.polygon_mode = .Line
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

    mu_mlw.init()
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
    
    init_planet(&_planet, 14)
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

    projection := math.Mat4f(1)
    projection = linalg.matrix4_perspective_f32(linalg.radians(cast(f32)45), f32(WIDTH) / f32(HEIGHT), 0.1, 100)
    

    view := math.Mat4f(1)
    view = linalg.matrix4_translate_f32({0, 0, -10})

    input_uniforms: Vertex_Uniforms
    input_uniforms.view = view
    input_uniforms.projection = projection

    angle: f32
    running := true 
    for running {
        for event in platform.poll_event() {
            #partial switch in event {
                case core.Quit_Event: {
                    running = false
                }
            }
        }
        mu.begin(&mu_mlw._state.mu_ctx)
        //mu_mlw.all_windows(&mu_mlw._state.mu_ctx)
        if mu.window(&mu_mlw._state.mu_ctx, "Hello", {0, 0, 300, 300}) {
            if .SUBMIT in mu.button(&mu_mlw._state.mu_ctx, "Hello") {
                fmt.printf("Pressed")
            }
        }
        
        mu.end(&mu_mlw._state.mu_ctx)

        angle += 1
        input_uniforms.model = math.Mat4f(1)
        input_uniforms.model *= linalg.matrix4_translate_f32({0, 0, 0})
        input_uniforms.model *= linalg.matrix4_rotate_f32(linalg.radians(angle), {1.0, 1.0, 0.0})
        //input_uniforms.model *= linalg.matrix4_scale_f32({0.4, 0.4, 0.4})

        gpu.begin_default_pass(pass_action, WIDTH, HEIGHT)
        //gpu.apply_pipeline(pipeline)
        //gpu.apply_input_buffers(input_buffers)
        //gpu.apply_uniforms_raw(.Vertex, 0, &input_uniforms, size_of(input_uniforms))
        //gpu.draw(0, len(planet_indices), 1)
        mu_mlw.render(&mu_mlw._state.mu_ctx, WIDTH, HEIGHT)
        /*
        for face in _planet.terrain_faces {
            gpu.buffer_data(planet_vb, slice.to_bytes(face.mesh.vertices))
            gpu.buffer_data(planet_ib, slice.to_bytes(face.mesh.indices))
            gpu.draw(0, len(face.mesh.indices), 1)
        }*/
        gpu.end_pass()

        platform.update_window()

        free_all(context.temp_allocator)
    }
}