package mlw_core

Step_Procedure :: #type proc(dt: f32)

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
    vsync: bool,
    variant: union {
        OpenGL_Info,
    },
}

Window_Info :: struct {
    title: string,
    size: [2]int,
}

Platform_Info :: struct {
    step: Step_Procedure,
    window: Window_Info,
    graphics: Graphics_Info,
}