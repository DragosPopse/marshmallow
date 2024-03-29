package mmlow_platform 

import "../core"
import "event"
import "../math/mathi"
import "../math/mathf"
import "../math"

Window_Info :: core.Window_Info
Graphics_Info :: core.Graphics_Info
Init_Info :: core.Platform_Info


Backend_Init :: #type proc(info: Init_Info)
Backend_Teardown :: #type proc()

Backend_Update_Window :: #type proc()
Backend_Poll_Event :: #type proc() -> (ev: event.Event, ok: bool)
Backend_Get_Backend_Window :: #type proc() -> (window: rawptr)

Backend_Key_Down :: #type proc(key: event.Key) -> (down: bool)

Backend_Get_Mouse_Position :: #type proc() -> (position: mathf.Vec2)
