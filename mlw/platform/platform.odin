package mmlow_platform

import "../core"
import "core:runtime"
import "core:time"
import "core:fmt"

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
        clock: time.Stopwatch
        time.stopwatch_start(&clock)
        for is_running {
            dt := cast(f32)time.duration_seconds(time.stopwatch_duration(clock))
            time.stopwatch_reset(&clock)
            time.stopwatch_start(&clock)
            step_proc(dt)
        }
    }

    quit :: proc "contextless" () {
        is_running = false
    }

    
}

