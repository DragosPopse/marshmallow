package mmlow_core 

STR_UNDEFINED_CONFIG :: "UNDEFINED"

GPU_Backend_Family :: enum {
    OpenGL,
}

GPU_Backend_Type :: enum {
    glcore3,
}

Platform_Backend_Type :: enum {
    sdl2,
}

@(private = "file")
PLATFORM_BACKEND_CONFIG :: #config(MLW_PLATFORM_BACKEND, STR_UNDEFINED_CONFIG)

@(private = "file")
GPU_BACKEND_CONFIG :: #config(MLW_GPU_BACKEND, STR_UNDEFINED_CONFIG)

when PLATFORM_BACKEND_CONFIG == STR_UNDEFINED_CONFIG {
    //Todo(Dragos): This should be ODIN_OS specific
    PLATFORM_BACKEND :: Platform_Backend_Type.sdl2 
} else when PLATFORM_BACKEND_CONFIG == "sdl2" {
    PLATFORM_BACKEND :: Platform_Backend_Type.sdl2 
} else {
    #panic("PLATFORM_BACKEND not available.")
}

when GPU_BACKEND_CONFIG == STR_UNDEFINED_CONFIG {
    //Todo(Dragos): This should be ODIN_OS specific
    GPU_BACKEND :: GPU_Backend_Type.glcore3
    GPU_BACKEND_FAMILY :: GPU_Backend_Family.OpenGL 
} else when GPU_BACKEND_CONFIG == "glcore3" {
    GPU_BACKEND :: GPU_Backend_Type.glcore3
    GPU_BACKEND_FAMILY :: GPU_Backend_Family.OpenGL 
}
