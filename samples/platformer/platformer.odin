package main

import "core:fmt"
import "../../mlw/core"
import "../../mlw/gpu"
import "../../mlw/platform" 
import "../../mlw/platform/event"
import "../../mlw/imdraw"


tick :: proc(dt: f32) {
    for ev in platform.poll_event() {
        #partial switch ev.type {
        case .Quit: 
            platform.quit()
        }
    }
}


main :: proc() {
    platform_info: platform.Init_Info
    platform_info.graphics = gpu.default_graphics_info()
    platform_info.step = tick
    platform_info.window.size = {800, 600}
    platform_info.window.title = "PlatFormers"
    
    platform.init(platform_info)
    gpu.init()
    imdraw.init()

    platform.start()
}