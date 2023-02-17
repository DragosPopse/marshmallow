package mmlow_core

Graphics_Context :: distinct rawptr

OpenGL_Profile :: enum {
    Core,
    ES,
    Compatibility,
}

OpenGL_Context_Info :: struct {
    major, minor: int,
    profile: OpenGL_Profile,
}

Graphics_Context_Info :: union {
    OpenGL_Context_Info,
}