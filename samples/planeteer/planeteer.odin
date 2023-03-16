package main

import "core:fmt"
import "core:mem"
import "../../mlw/core"
import "../../mlw/gpu"
import "../../mlw/math"
import "../../mlw/platform"
import linalg "core:math/linalg"
import "core:slice"
import mu "vendor:microui"
import mu_mlw "../../mlw/third/microui"
import "../../mlw/platform/event"
import "core:time"

when ODIN_OS != .JS {
    import "core:thread"
}


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

create_standard_pipeline :: proc(shader: gpu.Shader, polygon_mode: core.Polygon_Mode) -> (pipeline: gpu.Pipeline) {
    pipe_info: gpu.Pipeline_Info
    blend: core.Blend_State
    blend.rgb.src_factor = .Src_Alpha
    blend.rgb.dst_factor = .One_Minus_Src_Alpha
    blend.alpha = blend.rgb
    pipe_info.color.blend = blend
    pipe_info.shader = shader
    pipe_info.index_type = .u32 
    pipe_info.primitive_type = .Triangles
    pipe_info.polygon_mode = polygon_mode
    depth: core.Depth_State
    pipe_info.depth = depth // Note(Dragos): not fully implemented

    pipe_info.layout = core.layout_from_structs([]core.Struct_Layout_Info{
        0 = {Vertex, .Per_Vertex},
    })

    return gpu.create_pipeline(pipe_info)
}

WIDTH, HEIGHT := 800, 800
_planet: Planet
ui: ^mu.Context

initialize :: proc() {
    platform_info: platform.Init_Info
    platform_info.window.size = {WIDTH, HEIGHT}
    platform_info.window.title = "Planeteer"
    platform_info.graphics = gpu.default_graphics_info()
    platform.init(platform_info)
    gpu.init()

    ui = mu_mlw.init()
}


main :: proc() {
    frame_clock, gen_clock, render_clock, buffer_update_clock: time.Stopwatch
    initialize()
    shader: gpu.Shader
    shader_err: Maybe(string)
    if shader, shader_err = create_standard_shader(); shader_err != nil {
        fmt.panicf("SHADER_ERR: %s\n", shader_err.(string))
    }
    default_pipeline := create_standard_pipeline(shader, .Fill)
    wireframe_pipeline := create_standard_pipeline(shader, .Line)
    
    settings: Settings
    frame_info: Frame_Info
    settings.planet = default_planet_settings()
    init_planet(&_planet)
   
    
    planet_vb: gpu.Buffer
    {
        info: gpu.Buffer_Info
        info.type = .Vertex
        info.data = nil
        info.size = VB_SIZE
        info.usage_hint = .Dynamic
        planet_vb = gpu.create_buffer(info)
    }
    
    planet_ib: gpu.Buffer
    {
        info: gpu.Buffer_Info
        info.type = .Index
        info.data = nil
        info.size = IB_SIZE
        info.usage_hint = .Dynamic
        planet_ib = gpu.create_buffer(info)
    }

    when ODIN_OS != .JS {
        pool: thread.Pool
        thread.pool_init(&pool, context.allocator, 6)
        thread.pool_start(&pool)
        defer thread.pool_finish(&pool)
    }
    
    time.stopwatch_start(&gen_clock)
    when ODIN_OS != .JS {
        construct_planet_mesh(&_planet, settings.planet, &pool)
    } else {
        construct_planet_mesh_single_threaded(&planet, settings.planet)
    }
    planet_vertices, planet_indices := merge_planet_meshes(_planet, context.temp_allocator)
    gpu.buffer_data(planet_vb, slice.to_bytes(planet_vertices))
    gpu.buffer_data(planet_ib, slice.to_bytes(planet_indices))
    frame_info.gen_time = cast(f32)time.duration_seconds(time.stopwatch_duration(gen_clock))
    time.stopwatch_reset(&gen_clock)

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
    draw_ui := false
    time.stopwatch_start(&frame_clock)
    for running {
        frame_info.frame_time = cast(f32)time.duration_seconds(time.stopwatch_duration(frame_clock))
        time.stopwatch_reset(&frame_clock)
        time.stopwatch_start(&frame_clock)

        for ev in platform.poll_event() {
            mu_mlw.process_platform_event(ui, ev)
            #partial switch ev.type {
                case .Quit: {
                    running = false
                }
            }
        }
        mu.begin(ui)
        graphics_changed, planet_changed := settings_window(ui, &settings, frame_info)
        mu.end(ui)

        if planet_changed {
            time.stopwatch_start(&gen_clock)

            destroy_planet(_planet)
            when ODIN_OS != .JS {
                construct_planet_mesh(&_planet, settings.planet, &pool)
            } else {
                construct_planet_mesh_single_threaded(&_planet, settings.planet)
            }

            frame_info.gen_time = cast(f32)time.duration_seconds(time.stopwatch_duration(gen_clock))
            time.stopwatch_reset(&gen_clock)

            time.stopwatch_start(&buffer_update_clock)

            planet_vertices, planet_indices = merge_planet_meshes(_planet, context.temp_allocator)
            gpu.buffer_data(planet_vb, slice.to_bytes(planet_vertices))
            gpu.buffer_data(planet_ib, slice.to_bytes(planet_indices))

            frame_info.buffer_update_time = cast(f32)time.duration_seconds(time.stopwatch_duration(buffer_update_clock))
            time.stopwatch_reset(&buffer_update_clock)
        }

        angle += 1
        input_uniforms.model = math.Mat4f(1)
        input_uniforms.model *= linalg.matrix4_translate_f32({0, 0, 0})
        input_uniforms.model *= linalg.matrix4_rotate_f32(linalg.radians(angle), {1.0, 1.0, 0.0})
        //input_uniforms.model *= linalg.matrix4_scale_f32({0.4, 0.4, 0.4})

        gpu.begin_default_pass(pass_action, WIDTH, HEIGHT)
        if settings.graphics.wireframe {
            gpu.apply_pipeline(wireframe_pipeline)
        } else {
            gpu.apply_pipeline(default_pipeline)
        }  
        gpu.apply_input_buffers(input_buffers)
        gpu.apply_uniforms_raw(.Vertex, 0, &input_uniforms, size_of(input_uniforms))
        gpu.draw(0, len(planet_indices), 1)
        mu_mlw.apply_microui_pipeline(WIDTH, HEIGHT)
        mu_mlw.draw(ui)
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