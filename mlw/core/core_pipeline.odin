package mmlow_core


Polygon_Mode :: enum {
    Fill, // Default
    Line,
    Point,
}

Primitive_Type :: enum {
    Triangles,
    Lines,
    Line_Strip,
}

Pipeline :: distinct u32 

Stencil_State :: struct {

}

Depth_State :: struct {

}

Color_State :: struct {
    blend: Maybe(Blend_State),
}

Color :: [4]byte // Note(Dragos): This should be a distinct type somewhere i think

Pixel_Format :: struct {
    
}

Cull_Mode :: enum {
    None,
    Front,
    Back,
}

Pipeline_Info :: struct {
    shader: Shader,
    stencil: Maybe(Stencil_State),
    color: Color_State, // Note(Dragos): We should allow multiple color states, but idk what it does yet. Better to simplify
    depth: Maybe(Depth_State),
    blend_color: Color,
    cull_mode: Cull_Mode,
    primitive_type: Primitive_Type,
    polygon_mode: Polygon_Mode,
    layout: Layout_Info,
    index_type: Index_Type,
}