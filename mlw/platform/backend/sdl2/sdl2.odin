package highland_platform_backend_sdl2

import sdl "vendor:sdl2"
import "../../../core"

@(private = "package")
window_flags: sdl.WindowFlags

@(private = "package")
_close_window := false

init :: proc() {
    core.gl_set_proc_address = sdl.gl_set_proc_address
}