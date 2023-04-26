package mmlow_platform

import "../core"
import "core:runtime"
import "core:time"
import "core:fmt"
import cmath "core:math"

import "event"

Step_Procedure :: core.Step_Procedure

step_proc: Step_Procedure

// This is modified by the platform. Read-only
delta_time: f32


// From raylib my beloved
get_fps :: proc() -> (fps: int) {
    FPS_CAPTURE_FRAMES_COUNT :: 30
    FPS_AVERAGE_TIME_SECONDS :: 0.5
    FPS_STEP :: FPS_AVERAGE_TIME_SECONDS / FPS_CAPTURE_FRAMES_COUNT
    @static index := 0
    @static average, last: f32 = 0, 0
    @static history: [FPS_CAPTURE_FRAMES_COUNT]f32 = 0

    now := cast(f32)time.duration_seconds(transmute(time.Duration)time.tick_now())
    if delta_time == 0 do return 0
    if now - last > FPS_STEP {
        last = now
        index = (index + 1) % FPS_CAPTURE_FRAMES_COUNT
        average -= history[index]
        history[index] = delta_time / FPS_CAPTURE_FRAMES_COUNT
        average += history[index]
    }
    fps = cast(int)cmath.round(1.0 / average)
    return fps
}




// Js requires an exported step procedure that runs weird.
when ODIN_OS == .JS {
    @(export, link_name = "step")
    js_step :: proc "contextless" (dt: f64, ctx: runtime.Context) {
        context = ctx
        delta_time = dt
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
            delta_time = cast(f32)time.duration_seconds(time.stopwatch_duration(clock))
            time.stopwatch_reset(&clock)
            time.stopwatch_start(&clock)
            step_proc(delta_time)
        }
    }

    quit :: proc "contextless" () {
        is_running = false
    }
}

