package highland_platform 

import "../core"

BACKEND :: core.PLATFORM_BACKEND

when BACKEND == .sdl2 {
    import backend "backend/sdl2"
} else {
    #panic("Unsupported PLATFORM_BACKEND")
}

Window :: backend.Window
poll_events :: backend.poll_events
init :: backend.init
create_window :: backend.create_window
destroy_window :: backend.destroy_window
swap_buffers :: backend.swap_buffers
window_should_close :: backend.window_should_close