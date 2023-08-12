package mmlow_platform 

import "../core"
import "core:runtime"
import "event"
import "../math/mathf"

BACKEND :: core.PLATFORM_BACKEND
import "backend/sdl2"
import "backend/wasi"
import "backend/js"

when BACKEND == .SDL2 {
    backend :: sdl2
} else when BACKEND == .Native {
    when ODIN_OS == .JS {
        backend :: js
    } else when ODIN_OS == .WASI {
        backend :: wasi
    } else {
        #panic("Unsupported platform")
    }
}


init :: proc(info: Init_Info) {
    assert(info.step != nil, "The step procedure is not set.")
    step_proc = info.step
    backend.init(info)
}

teardown :: proc() {
    backend.teardown()
}

update_window :: proc() {
    backend.update_window()
}
poll_event :: proc() -> (ev: event.Event, ok: bool) {
    return backend.poll_event()
}

get_backend_window :: proc() -> rawptr {
    return backend.get_backend_window()
}

get_mouse_position :: proc() -> mathf.Vec2 {
    return backend.get_mouse_position()
}

key_down :: proc(key: event.Key) -> bool {
    return backend.key_down(key)
}

when ODIN_OS == .JS {
    default_context :: backend.default_context
} else {
    default_context :: runtime.default_context
}