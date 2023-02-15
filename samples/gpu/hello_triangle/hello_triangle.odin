package main


import "core:slice"
import "core:fmt"
import gl "vendor:OpenGL"

import "../../../mlw/gpu"
import "../../../mlw/platform"
import "../../../mlw/image"
import "../../../mlw/math"
import "../../../mlw/core"

Frag_Uniforms :: struct {
    u_Color: math.Vec3f `u_Color`,
}

// Note(Dragos): write shader for each sample
create_test_shader :: proc() -> (shader: gpu.Shader) {
    vert_info: gpu.Shader_Stage_Info
    frag_info: gpu.Shader_Stage_Info
    vert, frag: gpu.Shader_Stage
    err: Maybe(string)

    vert_info.src = #load("../../../mlw/gpu/backend/glcore3/shaders/basic.vert", string) 
    vert_info.type = .Vertex
    if vert, err = gpu.create_shader_stage(vert_info); err != nil {
        fmt.printf("VERT_ERR: %v\n", err)
        return
    }
    defer gpu.destroy_shader_stage(vert)
    frag_info.src = #load("../../../mlw/gpu/backend/glcore3/shaders/basic.frag", string)
    frag_info.type = .Fragment

    frag_info.uniform_blocks[0].size = size_of(Frag_Uniforms)
    frag_info.uniform_blocks[0].uniforms[0].name = "u_Color"
    frag_info.uniform_blocks[0].uniforms[0].type = .vec3f32
    
    frag_info.textures[0] = {
        name = "u_Tex1",
        type = .Texture2D,
    }
    /*
    frag_info.textures[1] = {
        name = "u_Tex2",
        type = .Texture2D,
    }*/


    if frag, err = gpu.create_shader_stage(frag_info); err != nil {
        fmt.printf("FRAG_ERR: %v\n", err)
        return
    }
    defer gpu.destroy_shader_stage(frag)

    shader_info: gpu.Shader_Info
    shader_info.stages[.Vertex] = vert
    shader_info.stages[.Fragment] = frag
    if shader, err = gpu.create_shader(shader_info, false); err != nil {
        fmt.printf("SHADER_ERR: %s\n", err.(string))
    }
    // what to do with shader_info.attrs? 
    return
}

Vertex :: struct #packed {
    pos: [3]f32 `COORD`,
    tex: [2]f32 `TEXCOORD`,
}

vertices := [?]Vertex {
    {
        pos = {0.5, 0.5, 0.0},
        tex = {1, 1},
    },
    {
        pos = {0.5, -0.5, 0.0},
        tex = {1, 0},
    },
    {
        pos = {-0.5, -0.5, 0.0},
        tex = {0, 0},
    },
    {
        pos = {-0.5, 0.5, 0.0},
        tex = {0, 1},
    },
}

indices := [?]u32 {
    0, 1, 3,
    1, 2, 3,
}

main :: proc() {
    platform.init()
    window := platform.create_window("Test", 600, 600) // create window before gpu.init
    gpu.init()

    shader := create_test_shader()
    
    fmt.printf("GL_VERSION: %s\n", gl.GetString(gl.VERSION));


    buff_desc: gpu.Buffer_Info 
    buff_desc.type = .Vertex
    buff_desc.usage_hint = .Immutable
    buff_desc.size = size_of(vertices)
    buff_desc.data = slice.to_bytes(vertices[:])
    vert_buff := gpu.create_buffer(buff_desc)

    ind_desc: gpu.Buffer_Info
    ind_desc.type = .Index
    ind_desc.usage_hint = .Immutable
    ind_desc.size = size_of(indices)
    ind_desc.data = slice.to_bytes(indices[:])
    ind_buff := gpu.create_buffer(ind_desc)
   
    pipe_info: gpu.Pipeline_Info
    blend: core.Blend_State
    blend.rgb.src_factor = .Src_Alpha
    blend.rgb.dst_factor = .One_Minus_Src_Alpha
    blend.alpha = blend.rgb
    pipe_info.color.blend = blend
    pipe_info.shader = shader
    pipe_info.index_type = .u32 
    pipe_info.primitive_type = .Triangles

    /*
    pipe_info.layout.buffers[0] = {
        stride = size_of(Vertex),
        step = .Per_Vertex,
    }

    pipe_info.layout.attrs[0] = {
        buffer_index = 0,
        offset = 0,
        format = .vec3f32,
    }

    pipe_info.layout.attrs[1] = {
        buffer_index = 0,
        offset = 3 * size_of(f32),
        format = .vec2f32,
    }
    */


    pipe_info.layout = core.layout_from_structs([]core.Struct_Layout_Info{
        0 = {Vertex, .Per_Vertex},
    })
   

    pipeline := gpu.create_pipeline(pipe_info)
    tex1, tex2: gpu.Texture
    {
        texture_info: gpu.Texture_Info
        img, _ := image.load_image_from_file("../../assets/textures/coin.png")
        defer image.delete_image(img)
        texture_info.type = .Texture2D
        texture_info.data = slice.to_bytes(img.pixels)
        texture_info.generate_mipmap = false
        texture_info.size.x = img.size.x 
        texture_info.size.y = img.size.y
        texture_info.min_filter = .Nearest
        texture_info.mag_filter = .Nearest
        tex1 = gpu.create_texture(texture_info)
    }

    {
        texture_info: gpu.Texture_Info
        img, _ := image.load_image_from_file("../../assets/textures/hero.png")
        defer image.delete_image(img)
        texture_info.type = .Texture2D
        texture_info.data = slice.to_bytes(img.pixels)
        texture_info.generate_mipmap = true
        texture_info.size.x = img.size.x 
        texture_info.size.y = img.size.y
        tex2 = gpu.create_texture(texture_info)
    }
    

    input_buffers: gpu.Input_Buffers
    input_buffers.buffers[0] = vert_buff
    input_buffers.index = ind_buff
    
    input_textures: gpu.Input_Textures
    input_textures.textures[.Fragment][0] = tex1
    input_textures.textures[.Fragment][1] = tex2

    gl.ClearColor(0.012, 0.533, 0.988, 1.0)
    for !platform.window_should_close() {
        platform.poll_events(window)
        frag_uniforms: Frag_Uniforms
        frag_uniforms.u_Color = {1, 1, 1}
        gpu.apply_pipeline(pipeline)
        //gl.Enable(gl.BLEND)
        //gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
        gpu.apply_input_buffers(input_buffers)
        gpu.apply_input_textures(input_textures)
        gpu.apply_uniforms_raw(.Fragment, 0, &frag_uniforms, size_of(frag_uniforms))
        gl.Clear(gl.COLOR_BUFFER_BIT)
        gpu.draw(0, 6)
        platform.swap_buffers(window)
    }
}
