package mmlow_math

Colorb :: distinct [4]byte
Colorf :: distinct [4]f32

bBLACK :: Colorb{0, 0, 0, 255}
fBLACK :: Colorf{0, 0, 0, 1}

bWHITE :: Colorb{255, 255, 255, 255}
fWHITE :: Colorf{1, 1, 1, 1}

bRED :: Colorb{255, 0, 0, 255}
fRED :: Colorf{1, 0, 0, 1}

bGREEN :: Colorb{0, 255, 0, 255}
fGREEN :: Colorf{0, 1, 0, 1}

bBLUE :: Colorb{0, 0, 255, 255}
fBLUE :: Colorf{0, 0, 1, 1}

to_colorf :: proc(color: Colorb) -> (result: Colorf) {
    result.r = cast(f32)color.r / 255
    result.g = cast(f32)color.r / 255
    result.b = cast(f32)color.r / 255
    result.a = cast(f32)color.r / 255 
    return result
}

to_colorb :: proc(color: Colorf) -> (result: Colorb) {
    panic("math.to_colorb not implemented")
}