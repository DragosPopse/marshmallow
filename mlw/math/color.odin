package mlw_math

// RGBA Color
Color4b :: distinct [4]byte
Color4f :: distinct [4]f32

// RGB Color
Color3b :: distinct [3]byte
Color3f :: distinct [3]f32

BRGBA_BLACK :: Color4b{0, 0, 0, 255}
FRGBA_BLACK :: Color4f{0, 0, 0, 1}

WHITE_4b :: Color4b{255, 255, 255, 255}
WHITE_4f :: Color4f{1, 1, 1, 1}

RED_4b :: Color4b{255, 0, 0, 255}
RED_4f :: Color4f{1, 0, 0, 1}

GREEN_4b :: Color4b{0, 255, 0, 255}
GREEN_4f :: Color4f{0, 1, 0, 1}

BLUE_4b :: Color4b{0, 0, 255, 255}
BLUE_4f :: Color4f{0, 0, 1, 1}



/*
to_colorf :: proc(color: Colorb) -> (result: Colorf) {
    result.r = cast(f32)color.r / 255
    result.g = cast(f32)color.g / 255
    result.b = cast(f32)color.b / 255
    result.a = cast(f32)color.a / 255  //this is the problem. It was working when it was buggy. wtf
    return result
}

to_colorb :: proc(color: Colorf) -> (result: Colorb) {
    panic("math.to_colorb not implemented")
}
*/

// god this naming sucks goof
color3b_to_color3f :: proc(color: Color3b) -> (result: Color3f) {
    result.r = cast(f32)color.r / 255
    result.g = cast(f32)color.g / 255
    result.b = cast(f32)color.b / 255
    return result
}

color4b_to_color4f :: proc(color: Color4b) -> (result: Color4f) {
    result.r = cast(f32)color.r / 255
    result.g = cast(f32)color.g / 255
    result.b = cast(f32)color.b / 255
    result.a = cast(f32)color.a / 255
    return result
}

to_color3f :: proc {
    color3b_to_color3f,
}

to_color4f :: proc {
    color4b_to_color4f,
}

color3f_to_color3b :: proc(color: Color3f) -> (result: Color3b) {
    result.r = byte(clamp(color.r, 0, 1) * 255)
    result.g = byte(clamp(color.g, 0, 1) * 255)
    result.b = byte(clamp(color.b, 0, 1) * 255)
    return result
}

to_color3b :: proc {
    color3f_to_color3b,
}

