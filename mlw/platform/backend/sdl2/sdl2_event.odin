package highland_platform_backend_sdl2

import sdl "vendor:sdl2"
import "../../../core"

poll_event :: proc() -> (event: core.Event, ok: bool) {
    ev: sdl.Event 
    if sdl.PollEvent(&ev) {
        #partial switch ev.type {
            case .QUIT: {
                res: core.Quit_Event
                return res, true
            }

            case .KEYDOWN: {
                res: core.Key_Event
                res.action = .Down
                res.key = _SCANCODE_TO_KEY[ev.key.keysym.scancode]
                return res, true
            }

            case .KEYUP: {
                res: core.Key_Event
                res.action = .Down
                res.key = _SCANCODE_TO_KEY[ev.key.keysym.scancode]
                return res, true
            }
        }
        // Unhandled event type, but still an event nontheless
        return nil, true
    } 

    return nil, false
}