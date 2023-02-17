package highland_platform 

import "../core"

BACKEND :: core.PLATFORM_BACKEND

when BACKEND == .sdl2 {
    import backend "backend/sdl2"
} else {
    #panic("Unsupported PLATFORM_BACKEND")
}


init: Backend_Init : backend.init
teardown: Backend_Teardown : backend.teardown

create_window: Backend_Create_Window : backend.create_window
destroy_window: Backend_Destroy_Window : backend.destroy_window
swap_buffers: Backend_Swap_Buffers : backend.swap_buffers
poll_event: Backend_Poll_Event : backend.poll_event

create_graphics_context: Backend_Create_Graphics_Context : backend.create_graphics_context