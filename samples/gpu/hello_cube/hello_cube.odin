package main

import "core:fmt"
import "core:slice"

import "../../../mlw/core"
import "../../../mlw/platform"
import "../../../mlw/image"
import "../../../mlw/math"
import "../../../mlw/gpu"

cube_vertices := [?]Vertex {
    {{-0.5, -0.5, -0.5}, {0.0, 0.0}},
    {{ 0.5, -0.5, -0.5}, {1.0, 0.0}},
    {{ 0.5,  0.5, -0.5}, {1.0, 1.0}},
    {{ 0.5,  0.5, -0.5}, {1.0, 1.0}},
    {{-0.5,  0.5, -0.5}, {0.0, 1.0}},
    {{-0.5, -0.5, -0.5}, {0.0, 0.0}},

    {{-0.5, -0.5,  0.5}, {0.0, 0.0}},
    {{ 0.5, -0.5,  0.5}, {1.0, 0.0}},
    {{ 0.5,  0.5,  0.5}, {1.0, 1.0}},
    {{ 0.5,  0.5,  0.5}, {1.0, 1.0}},
    {{-0.5,  0.5,  0.5}, {0.0, 1.0}},
    {{-0.5, -0.5,  0.5}, {0.0, 0.0}},

    {{-0.5,  0.5,  0.5}, {1.0, 0.0}},
    {{-0.5,  0.5, -0.5}, {1.0, 1.0}},
    {{-0.5, -0.5, -0.5}, {0.0, 1.0}},
    {{-0.5, -0.5, -0.5}, {0.0, 1.0}},
    {{-0.5, -0.5,  0.5}, {0.0, 0.0}},
    {{-0.5,  0.5,  0.5}, {1.0, 0.0}},

    {{ 0.5,  0.5,  0.5}, {1.0, 0.0}},
    {{ 0.5,  0.5, -0.5}, {1.0, 1.0}},
    {{ 0.5, -0.5, -0.5}, {0.0, 1.0}},
    {{ 0.5, -0.5, -0.5}, {0.0, 1.0}},
    {{ 0.5, -0.5,  0.5}, {0.0, 0.0}},
    {{ 0.5,  0.5,  0.5}, {1.0, 0.0}},

    {{-0.5, -0.5, -0.5}, {0.0, 1.0}},
    {{ 0.5, -0.5, -0.5}, {1.0, 1.0}},
    {{ 0.5, -0.5,  0.5}, {1.0, 0.0}},
    {{ 0.5, -0.5,  0.5}, {1.0, 0.0}},
    {{-0.5, -0.5,  0.5}, {0.0, 0.0}},
    {{-0.5, -0.5, -0.5}, {0.0, 1.0}},

    {{-0.5,  0.5, -0.5}, {0.0, 1.0}},
    {{ 0.5,  0.5, -0.5}, {1.0, 1.0}},
    {{ 0.5,  0.5,  0.5}, {1.0, 0.0}},
    {{ 0.5,  0.5,  0.5}, {1.0, 0.0}},
    {{-0.5,  0.5,  0.5}, {0.0, 0.0}},
    {{-0.5,  0.5, -0.5}, {0.0, 1.0}},
}

WIDTH :: 600
HEIGHT :: 600

init_platform :: proc() {
    info: platform.Init_Info
    info.window.size = {WIDTH, HEIGHT}
    info.graphics = gpu.default_graphics_info()
    platform.init(info)
}

create_default_shader :: proc() -> (shader: gpu.Shader, err: Maybe(string)) {
    vert_info: gpu.Shader_Stage_Info
    vert: gpu.Shader_Stage
    vert_info.src = #load("shaders/basic.vert", string)
    vert_info.type = .Vertex

    if vert, err = gpu.create_shader_stage(vert_info); err != nil {
        return 0, err
    }
    defer gpu.destroy_shader_stage(vert)

    frag_info: gpu.Shader_Stage_Info
    frag: gpu.Shader_Stage
    frag_info.src = #load("shaders/basic.frag", string)
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

create_default_pipeline :: proc(shader: gpu.Shader) -> (pipeline: gpu.Pipeline) {
    pipe_info: gpu.Pipeline_Info
    blend: core.Blend_State
    blend.rgb.src_factor = .Src_Alpha
    blend.rgb.dst_factor = .One_Minus_Src_Alpha
    blend.alpha = blend.rgb
    pipe_info.color.blend = blend
    pipe_info.shader = shader
    pipe_info.index_type = .u32 
    pipe_info.primitive_type = .Triangles
    pipe_info.layout = core.layout_from_structs([]core.Struct_Layout_Info{
        0 = {Vertex, .Per_Vertex},
    })
    pipeline = gpu.create_pipeline(pipe_info)
    return pipeline
}

create_vertex_buffer :: proc(vertices: []$T, size: int) -> (buffer: gpu.Buffer) {
    info: gpu.Buffer_Info
    info.type = .Vertex
    info.usage_hint = .Immutable
    info.data = slice.to_bytes(vertices)
    info.size = size
    return gpu.create_buffer(info)
}

create_texture_from_file :: proc(filename: string) -> (texture: gpu.Texture) {
    info: gpu.Texture_Info
    img, _ := image.load_image_from_file(filename)
    defer image.delete_image(img)
    info.data = slice.to_bytes(img.pixels)
    info.generate_mipmap = false 
    info.size.xy = img.size.xy
    info.min_filter = .Nearest
    info.mag_filter = .Nearest
    info.type = .Texture2D
    return gpu.create_texture(info)
}

// Note(Dragos): distinct types not supported by layout_from_struct. It's a bug
Vertex :: struct {
    pos: [3]f32,
    tex: [2]f32,
}



main :: proc() {
    init_platform()
    gpu.init()
    
    shader: gpu.Shader
    err: Maybe(string)

    if shader, err = create_default_shader(); err != nil {
        fmt.printf("Shader Error: %s\n", err.(string))
        return
    }
    
    pipeline := create_default_pipeline(shader)
    cube_buffer := create_vertex_buffer(cube_vertices[:], size_of(cube_vertices))

    pass_action := gpu.default_pass_action()
    pass_action.colors[0].value = math.Colorf{0.012, 0.533, 0.988, 1.0}
    
    texture := create_texture_from_file("assets/container.png")

    input_buffers: gpu.Input_Buffers
    input_buffers.buffers[0] = cube_buffer

    input_textures: gpu.Input_Textures
    input_textures.textures[.Fragment][0] = texture

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
        gpu.apply_input_textures(input_textures)
        gpu.draw(0, 36)
        gpu.end_pass()

        platform.update_window()
    }

    gpu.teardown()
    platform.teardown()
} 