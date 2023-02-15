package mmlow_core

Blend_Op :: enum {
    Add,
    Subtract,
    Reverse_Subtract,
}

Blend_Factor :: enum {
    Zero,
    One,
    Src_Color,
    One_Minus_Src_Color,
    Src_Alpha,
    One_Minus_Src_Alpha,
    Dst_Color,
    One_Minus_Dst_Color,
    Dst_Alpha,
    One_Minus_Dst_Alpha,
    Src_Alpha_Saturated,
    Blend_Color,
    Blend_Src_Alpha,
    Blend_Dst_Alpha,
}

Blend_Mode :: struct {
    src_factor: Blend_Factor,
    dst_factor: Blend_Factor,
    op: Blend_Op,
}

Blend_State :: struct {
    rgb: Blend_Mode,
    alpha: Blend_Mode,
}