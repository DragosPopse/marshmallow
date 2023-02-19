package mmlow_core

OpenGL_Profile :: enum {
    Core,
    ES,
    Compatibility,
}

OpenGL_Info :: struct {
    major, minor: int,
    profile: OpenGL_Profile,
}

Graphics_Info :: struct {
    color_bits, depth_bits, stencil_bits: int,
    debug: bool,
    variant: union {
        OpenGL_Info,
    },
}

Window_Info :: struct {
    title: string,
    size: [2]int,
}

Platform_Info :: struct {
    window: Window_Info,
    graphics: Graphics_Info,
}