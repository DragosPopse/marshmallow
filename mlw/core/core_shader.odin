package mmlow_core

import "core:mem"

// Todo(Dragos): Put all constants in 1 file ffs
MAX_UNIFORM_BLOCK_ELEMENTS :: 16
MAX_UNIFORM_BLOCKS :: 4

MAX_SHADER_TEXTURES :: 12

Uniform_Type :: enum {
    //bool, not supported -for now-
    i32,
    u32,
    f32,
    vec2f32,
    vec3f32,
    vec4f32,
    mat3f32,
    mat4f32,
}

Uniform_Info :: struct {
    name: string,
    type: Uniform_Type,
    array_count: uint,
}

Uniform_Block_Info :: struct {
    size: int,
    uniforms: [MAX_UNIFORM_BLOCK_ELEMENTS]Uniform_Info,
}

Shader_Attr_Info :: struct {
    name: string,
    index: int,
}

Shader_Stage_Type :: enum {
    Vertex,
    Fragment,
}

Shader_Texture_Info :: struct {
    name: string,
    type: Texture_Type,
}

Shader_Stage :: distinct u32
Shader :: distinct u32

Shader_Stage_Info :: struct {
    type: Shader_Stage_Type,
    // Note(Dragos): separate this into (Maybe) source and bytecode
    src: union {
        []u8,
        string,
    },
    uniform_blocks: [MAX_UNIFORM_BLOCKS]Uniform_Block_Info,
    textures: [MAX_SHADERSTAGE_TEXTURES]Shader_Texture_Info,
}



Shader_Info :: struct {
    attrs: [MAX_VERTEX_ATTRIBUTES]Shader_Attr_Info,
    stages: [Shader_Stage_Type]Maybe(Shader_Stage),
}

