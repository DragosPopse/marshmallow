package mmlow_platform 

import "../core"
import "core:runtime"

BACKEND :: core.PLATFORM_BACKEND

when BACKEND == .SDL2 {
    import backend "backend/sdl2"
} else when BACKEND == .Native {
    when ODIN_OS == .JS {
        import backend "backend/js"
    } else when ODIN_OS == .WASI {
        import backend "backend/wasi"
    } else {
        #panic("Unsupported platform")
    }
}


init :: proc(info: Init_Info) {
    assert(info.step != nil, "The step procedure is not set.")
    step_proc = info.step
    backend.init(info)
}

teardown: Backend_Teardown : backend.teardown

update_window: Backend_Update_Window : backend.update_window
poll_event: Backend_Poll_Event : backend.poll_event

get_backend_window: Backend_Get_Backend_Window : backend.get_backend_window

key_down: Backend_Key_Down : backend.key_down

when ODIN_OS == .JS {
    default_context :: backend.default_context
} else {
    import test "backend/js"
    default_context :: runtime.default_context
}