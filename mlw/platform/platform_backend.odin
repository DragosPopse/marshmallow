package highland_platform 

import "../core"

BACKEND :: core.PLATFORM_BACKEND

when BACKEND == .SDL2 {
    import backend "backend/sdl2"
} else {
    #panic("Unsupported PLATFORM_BACKEND")
}


init: Backend_Init : backend.init
teardown: Backend_Teardown : backend.teardown

update_window: Backend_Update_Window : backend.update_window
poll_event: Backend_Poll_Event : backend.poll_event

get_backend_window: Backend_Get_Backend_Window : backend.get_backend_window