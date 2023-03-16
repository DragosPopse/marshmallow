package mmlow_core 

STR_UNDEFINED_CONFIG :: "UNDEFINED"

GPU_Backend_Family :: enum {
    OpenGL, // Should this be OpenGL/OpenGLES/WebGL ?
    DirectX,
}

GPU_Backend_Type :: enum {
    glcore3,
    glcore4,
    gles2,
    webgl2,
    d3d11,
}

Platform_Backend_Type :: enum {
    SDL2,
    Native,
}

@(private = "file")
PLATFORM_BACKEND_CONFIG :: #config(MLW_PLATFORM_BACKEND, STR_UNDEFINED_CONFIG)

@(private = "file")
GPU_BACKEND_CONFIG :: #config(MLW_GPU_BACKEND, STR_UNDEFINED_CONFIG)

when PLATFORM_BACKEND_CONFIG == STR_UNDEFINED_CONFIG {
    //Todo(Dragos): This should be ODIN_OS specific
    when ODIN_OS == .JS {
        PLATFORM_BACKEND :: Platform_Backend_Type.Native
    } else {
        PLATFORM_BACKEND :: Platform_Backend_Type.SDL2
    }
} else when PLATFORM_BACKEND_CONFIG == "sdl2" {
    PLATFORM_BACKEND :: Platform_Backend_Type.SDL2 
} else when PLATFORM_BACKEND_CONFIG == "native" {
    PLATFORM_BACKEND :: Platform_Backend_Type.Native 
} else {
    #panic("PLATFORM_BACKEND not available.")
}

when GPU_BACKEND_CONFIG == STR_UNDEFINED_CONFIG {
    //Todo(Dragos): This should be ODIN_OS specific
    when ODIN_OS == .JS {
        GPU_BACKEND :: GPU_Backend_Type.webgl2
        GPU_BACKEND_FAMILY :: GPU_Backend_Family.OpenGL
    } else {
        GPU_BACKEND :: GPU_Backend_Type.glcore3
        GPU_BACKEND_FAMILY :: GPU_Backend_Family.OpenGL 
    }
} else when GPU_BACKEND_CONFIG == "glcore3" {
    GPU_BACKEND :: GPU_Backend_Type.glcore3
    GPU_BACKEND_FAMILY :: GPU_Backend_Family.OpenGL 
} else when GPU_BACKEND_CONFIG == "webgl2" {
    GPU_BACKEND :: GPU_Backend_Type.webgl2
    GPU_BACKEND_FAMILY :: GPU_Backend_Family.OpenGL
}
