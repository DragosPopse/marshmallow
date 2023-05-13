package mlw_core 


Texture :: distinct u32

MAX_SHADERSTAGE_TEXTURES :: 12 

Texture_Wrap_Mode :: enum {
    Repeat,
    Clamp_To_Edge,
    Clamp_To_Border,
    Mirrored_Repeat,
    Mirror_Clamp_To_Edge,
}

Texture_Min_Filter :: enum {
    Nearest,
    Linear,
    Nearest_Mip_Nearest,
    Linear_Mip_Nearest,
    Nearest_Mip_Linear,
    Linear_Mip_Linear,
}

Texture_Mag_Filter :: enum {
    Nearest,
    Linear,
}

Texture_Type :: enum {
    Invalid,
    Texture2D,
    Texture3D,
    Cubemap,
}

Pixel_Format :: enum {
    Invalid,
    A8,
    RGBA8,
    RGB8,
    DEPTH24_STENCIL8,
}


Texture_Info :: struct {
    size: [3]int,
    data: []byte,
    format: Pixel_Format,
    type: Texture_Type,
    min_filter: Texture_Min_Filter,
    mag_filter: Texture_Mag_Filter,
    wrap: [3]Texture_Wrap_Mode,
    generate_mipmap: bool,
    render_target: bool,
}

Input_Textures :: struct {
    textures: [Shader_Stage_Type][MAX_SHADERSTAGE_TEXTURES]Texture,
}