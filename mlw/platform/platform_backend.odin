package highland_platform 

import "../core"
import "core:runtime"

BACKEND :: core.PLATFORM_BACKEND

when BACKEND == .SDL2 {
    import backend "backend/sdl2"
} else when BACKEND == .Native {
    when ODIN_OS == .JS {
        import backend "backend/js"
    } else {
        #panic("Unsupported platform")
    }
}


init: Backend_Init : backend.init
teardown: Backend_Teardown : backend.teardown

update_window: Backend_Update_Window : backend.update_window
poll_event: Backend_Poll_Event : backend.poll_event

get_backend_window: Backend_Get_Backend_Window : backend.get_backend_window

when ODIN_OS == .JS {
    default_context :: backend.default_context
} else {
    default_context :: runtime.default_context
}