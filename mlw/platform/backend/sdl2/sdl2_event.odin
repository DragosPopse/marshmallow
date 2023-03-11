package highland_platform_backend_sdl2

import sdl "vendor:sdl2"
import "../../../core"
import "../../event"
import "core:strings"

poll_event :: proc() -> (ev: event.Event, ok: bool) {
    sdl_ev: sdl.Event 
    if sdl.PollEvent(&sdl_ev) {
        #partial switch sdl_ev.type {
            case .QUIT: {
                ev.type = .Quit
                return ev, true
            }
            
            // Todo(Dragos): Implement .Hold
            // Todo(Dragos): Rework events. It's not that nice right now
            case .KEYDOWN: {
                ev.type = .Key_Down
                ev.key.key = _SCANCODE_TO_KEY[sdl_ev.key.keysym.scancode]
                return ev, true
            }

            case .KEYUP: {
                ev.type = .Key_Up
                ev.key.key = _SCANCODE_TO_KEY[sdl_ev.key.keysym.scancode]
                return ev, true
            }

            case .MOUSEBUTTONDOWN: {
                ev.type = .Mouse_Down
                ev.button.button = _SDL_BUTTON_TO_MOUSE_BUTTON[sdl_ev.button.button]
                ev.button.position = {cast(int)sdl_ev.button.x, cast(int)sdl_ev.button.y}
                return ev, true
            }

            case .MOUSEBUTTONUP: {
                ev.type = .Mouse_Up
                ev.button.button = _SDL_BUTTON_TO_MOUSE_BUTTON[sdl_ev.button.button]
                ev.button.position = {cast(int)sdl_ev.button.x, cast(int)sdl_ev.button.y}
                return ev, true
            }

            case .MOUSEMOTION: {
                ev.type = .Mouse_Move
                ev.move.position = {cast(int)sdl_ev.motion.x, cast(int)sdl_ev.motion.y}
                ev.move.delta = {cast(int)sdl_ev.motion.xrel, cast(int)sdl_ev.motion.yrel}
                return ev, true
            }

            case .MOUSEWHEEL: {
                ev.type = .Mouse_Wheel
                ev.wheel.scroll = {cast(int)sdl_ev.wheel.x, cast(int)sdl_ev.wheel.y}
                return ev, true
            }

            case .TEXTINPUT: {
                ev.type = .Text_Input
                zero_idx := 0
                for c, i in sdl_ev.text.text {
                    if c == 0 {
                        zero_idx = i
                        break
                    }
                }
                ev.text.text = strings.clone_from_bytes(sdl_ev.text.text[:zero_idx], context.temp_allocator)
                return ev, true
            }
        }
        
        return {}, true // Unhandled event type, but still an event
    } 

    return {}, false
}