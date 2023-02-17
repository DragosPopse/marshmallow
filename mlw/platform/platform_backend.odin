package highland_platform 

import "../core"

BACKEND :: core.PLATFORM_BACKEND

when BACKEND == .sdl2 {
    import backend "backend/sdl2"
} else {
    #panic("Unsupported PLATFORM_BACKEND")
}


init: Backend_Init
teardown: Backend_Teardown

create_window: Backend_Create_Window
destroy_window: Backend_Destroy_Window 
swap_buffers: Backend_Swap_Buffers
window_is_open: Backend_Window_Is_Open
poll_events: Backend_Poll_Events

create_graphics_context: Backend_Create_Graphics_Context