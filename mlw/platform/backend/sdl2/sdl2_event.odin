package highland_platform_backend_sdl2

import sdl "vendor:sdl2"
import "../../../core"

poll_event :: proc(window: core.Window) -> (event: core.Event, ok: bool) {
    sdlwin := _get_sdl2_window(window)

    ev: sdl.Event 
    if sdl.PollEvent(&ev) {
        #partial switch ev.type {
            case .QUIT: {
                res: core.Quit_Event
                return res, true
            }
        }
    } else {
        return nil, false
    }

    // Unhandled event, but there are still some in the queue
    return nil, true
}