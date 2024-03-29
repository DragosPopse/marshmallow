package main

import "core:fmt"
import "core:slice"

import "../../../mlw/core"
import "../../../mlw/platform"
import "../../../mlw/image"
import "../../../mlw/math"
import "../../../mlw/gpu"

import "core:math/linalg"
import glm "core:math/linalg/glsl"

// Note(Dragos): distinct types not supported by layout_from_struct. It's a bug
Vertex :: struct {
    pos: [3]f32,
    tex: [2]f32,
}

Vertex_Uniforms :: struct {
    model, view, projection: math.Mat4f,
}

WIDTH :: 600
HEIGHT :: 600

quad_vertices := [?]Vertex {
    {{-1, -1, 0}, {0.0, 0.0}},
    {{ 1, -1, 0}, {1.0, 0.0}},
    {{ 1,  1, 0}, {1.0, 1.0}},
    {{ 1,  1, 0}, {1.0, 1.0}},
    {{-1,  1, 0}, {0.0, 1.0}},
    {{-1, -1, 0}, {0.0, 0.0}},
}

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



init_platform :: proc() {
    info: platform.Init_Info
    info.window.size = {WIDTH, HEIGHT}
    info.graphics = gpu.default_graphics_info()
    platform.init(info)
}

create_postfx_shader :: proc() -> (shader: gpu.Shader, err: Maybe(string)) {
    vert_info: gpu.Shader_Stage_Info
    vert: gpu.Shader_Stage
    vert_info.src = #load("shaders/postfx.vert", string)
    vert_info.type = .Vertex

    if vert, err = gpu.create_shader_stage(vert_info); err != nil {
        return 0, err
    }
    defer gpu.destroy_shader_stage(vert)

    frag_info: gpu.Shader_Stage_Info
    frag: gpu.Shader_Stage
    frag_info.src = #load("shaders/postfx.frag", string)
    frag_info.type = .Fragment
    frag_info.textures[0].name = "u_Tex1"
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

create_default_shader :: proc() -> (shader: gpu.Shader, err: Maybe(string)) {
    vert_info: gpu.Shader_Stage_Info
    vert: gpu.Shader_Stage
    vert_info.src = #load("shaders/basic.vert", string)
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
    frag_info.src = #load("shaders/basic.frag", string)
    frag_info.type = .Fragment
    frag_info.textures[0].name = "u_Tex1"
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
    depth: core.Depth_State
    pipe_info.depth = depth // Note(Dragos): not fully implemented
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
    img, ok := image.load_image_from_file(filename)
    if !ok {
        fmt.printf("Error loading image\n")
    }
    defer image.delete_image(img)
    info.data = slice.to_bytes(img.pixels)
    info.generate_mipmap = false 
    info.size.xy = img.size.xy
    info.min_filter = .Nearest
    info.mag_filter = .Nearest
    info.format = .RGBA8
    info.type = .Texture2D
    return gpu.create_texture(info)
}

create_framebuffer_texture :: proc(width, height: int) -> (color: gpu.Texture, depth_stencil: gpu.Texture) {
    cinfo: gpu.Texture_Info
    cinfo.render_target = true // needs to be a render target
    cinfo.generate_mipmap = false 
    cinfo.size.xy = {width, height}
    cinfo.min_filter = .Nearest
    cinfo.mag_filter = .Nearest
    cinfo.format = .RGB8
    cinfo.type = .Texture2D

    dsinfo: gpu.Texture_Info
    dsinfo.render_target = true // needs to be a render target
    dsinfo.generate_mipmap = false 
    dsinfo.size.xy = {width, height}
    dsinfo.min_filter = .Nearest
    dsinfo.mag_filter = .Nearest
    dsinfo.format = .DEPTH24_STENCIL8
    dsinfo.type = .Texture2D

    return gpu.create_texture(cinfo), gpu.create_texture(dsinfo)
}

create_frame_pass :: proc(texture: gpu.Texture, depth_stencil: gpu.Texture) -> (pass: gpu.Pass) {
    info: gpu.Pass_Info
    info.colors[0].texture = texture
    info.depth_stencil.texture = depth_stencil
    return gpu.create_pass(info)
}


main :: proc() {
    init_platform()
    gpu.init()
    
    shader: gpu.Shader
    err: Maybe(string)
    postfx_shader: gpu.Shader

    if shader, err = create_default_shader(); err != nil {
        fmt.printf("Shader Error: %s\n", err.(string))
        return
    }

    if postfx_shader, err = create_postfx_shader(); err != nil {
        fmt.printf("Shader Error: %s\n", err.(string))
        return
    }
    
    pipeline := create_default_pipeline(shader)
    postfx_pipeline := create_default_pipeline(postfx_shader)
    cube_buffer := create_vertex_buffer(cube_vertices[:], size_of(cube_vertices))
    quad_buffer := create_vertex_buffer(quad_vertices[:], size_of(quad_vertices))

    pass_action := gpu.default_pass_action()
    pass_action.colors[0].value = math.Colorf{0.012, 0.533, 0.988, 1.0}
    
    
    frame_texture, depth_stencil_texture := create_framebuffer_texture(WIDTH, HEIGHT)
    frame_pass := create_frame_pass(frame_texture, depth_stencil_texture)

    input_buffers: gpu.Input_Buffers
    input_buffers.buffers[0] = cube_buffer
    postfx_input_buffers: gpu.Input_Buffers
    postfx_input_buffers.buffers[0] = quad_buffer

    cube_texture := create_texture_from_file("assets/container.png")
    input_textures: gpu.Input_Textures
    input_textures.textures[.Fragment][0] = cube_texture

    postfx_input_textures: gpu.Input_Textures
    postfx_input_textures.textures[.Fragment][0] = frame_texture

    projection := math.Mat4f(1)
    projection = linalg.matrix4_perspective_f32(linalg.radians(cast(f32)45), f32(WIDTH) / HEIGHT, 0.1, 100)
    
    model := math.Mat4f(1)
    model = linalg.matrix4_rotate_f32(linalg.radians(cast(f32)-55), {1.0, 0.0, 0.0})

    view := math.Mat4f(1)
    view = linalg.matrix4_translate_f32({0, 0, -3})

    input_uniforms: Vertex_Uniforms
    input_uniforms.model = model
    input_uniforms.view = view
    input_uniforms.projection = projection

    

    running := true
    for running {
        for event in platform.poll_event() {
            #partial switch event.type {
                case .Quit: {
                    running = false
                }
            }
        }

        input_uniforms.model *= linalg.matrix4_rotate_f32(linalg.radians(cast(f32)-1), {1.0, 1.0, 0.0})

        // Render the cube onto a texture
        gpu.begin_pass(frame_pass, pass_action)
        gpu.apply_pipeline(pipeline)
        gpu.apply_input_buffers(input_buffers)
        gpu.apply_input_textures(input_textures)
        gpu.apply_uniforms_raw(.Vertex, 0, &input_uniforms, size_of(input_uniforms))
        gpu.draw(0, 36, 1)
        gpu.end_pass()

        // Render the output texture onto a quad and apply postfx
        gpu.begin_default_pass(pass_action, WIDTH, HEIGHT)
        gpu.apply_pipeline(postfx_pipeline)
        gpu.apply_input_buffers(postfx_input_buffers)
        gpu.apply_input_textures(postfx_input_textures)
        gpu.draw(0, 6, 1)
        gpu.end_pass()
        
        platform.update_window()
    }

    gpu.teardown()
    platform.teardown()
} 