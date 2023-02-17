package highland_platform 

import "../core"

Window :: core.Window
Window_Info :: core.Window_Info
Graphics_Context_Info :: core.Graphics_Context_Info
Graphics_Context :: core.Graphics_Context

Event :: core.Event

Backend_Init :: #type proc()
Backend_Teardown :: #type proc()

Backend_Create_Window :: #type proc(info: Window_Info) -> (window: Window)
Backend_Destroy_Window :: #type proc(window: Window)
Backend_Swap_Buffers :: #type proc(window: Window)
Backend_Poll_Event :: #type proc(window: Window) -> (ev: Event, ok: bool)

Backend_Create_Graphics_Context :: #type proc(window: Window, info: Graphics_Context_Info) -> (ctx: Graphics_Context, err: Maybe(string))

