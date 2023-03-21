package mmlow_platform

import "../core"
import "core:runtime"

Step_Procedure :: core.Step_Procedure

step_proc: Step_Procedure


// Js requires an exported step procedure that runs weird.
when ODIN_OS == .JS {
    @(export, link_name = "step")
    js_step :: proc "contextless" (dt: f64, ctx: runtime.Context) {
        context = ctx
        step_proc(cast(f32)dt)
    }

    start :: proc() {
        // Do nothing tbh
    }

    quit :: proc "contextless" () {

    }

    
} else {
    is_running := true

    start :: proc() {
        for is_running {
            step_proc(0.1)
        }
    }

    quit :: proc "contextless" () {
        is_running = false
    }

    
}

