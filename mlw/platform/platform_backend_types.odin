package highland_platform 

import "../core"

Window :: core.Window
Window_Info :: core.Window_Info
Graphics_Context_Info :: core.Graphics_Context_Info

Backend_Init :: #type proc()
Backend_Teardown :: #type proc()

Backend_Create_Window :: #type proc(info: Window_Info) -> (window: Window)
Backend_Destroy_Window :: #type proc(window: Window)
Backend_Swap_Buffers :: #type proc(window: Window)
Backend_Window_Is_Open :: #type proc(window: Window) -> bool
Backend_Poll_Events :: #type proc(window: Window)

Backend_Create_Graphics_Context :: #type proc(window: Window, info: Graphics_Context_Info) -> (err: Maybe(string))

