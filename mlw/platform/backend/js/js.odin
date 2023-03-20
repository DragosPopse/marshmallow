//+build js
package mmlow_platform_backend_js

import "../../event"
import "../../../core"
import "core:runtime"
import "core:mem"
import "core:fmt"
import "core:container/queue"

import "wasmem"
import "vendor:wasm/js"


WASM_MEMORY_PAGES :: #config(WASM_MEMORY_PAGES_CONFIG, 16384) // 1 GiB default


free_list: wasmem.Free_List
wasm_context: runtime.Context
scratch: mem.Scratch_Allocator

@(init)
_init_default_context :: proc "contextless" () {
    wasm_context = runtime.default_context()
    context = wasm_context
    fmt.printf("Allocating %v (%v bytes) pages for general purpose allocations\n", WASM_MEMORY_PAGES, WASM_MEMORY_PAGES * wasmem.PAGE_SIZE)
    
    if data, err := wasmem.page_alloc(WASM_MEMORY_PAGES); err == .None {
        wasmem.free_list_init(&free_list, data)
    } else {
        fmt.printf("Failed to allocate %v pages.", WASM_MEMORY_PAGES)
    }
    
    wasm_context.allocator = wasmem.free_list_allocator(&free_list)
    if err := mem.scratch_allocator_init(&scratch, 4 * mem.Megabyte, wasm_context.allocator); err != .None {
        fmt.printf("Failed to create scratch allocator.\n")
    }
    wasm_context.temp_allocator = mem.scratch_allocator(&scratch) // Todo(Dragos): Scratch allocator doesn't really work
}


default_context :: proc "contextless" () -> (ctx: runtime.Context) {
    return wasm_context
}

@(export, link_name = "odin_context_ptr")
odin_context_ptr :: proc "contextless" () -> (^runtime.Context) {
    return &wasm_context
}

init :: proc(info: core.Platform_Info) {
    queue.init_from_slice(&_events, _events_backing[:])
    // add_event_listener: the ID is getElementById thing. Give the ID of the canvas. Maybe the title of the window?
    /*js.add_window_event_listener(.Mouse_Down, nil, callback_mouse_down)
    js.add_window_event_listener(.Mouse_Up, nil, callback_mouse_up)
    js.add_window_event_listener(.Scroll, nil, callback_wheel)
    js.add_window_event_listener(.Mouse_Move, nil, callback_mouse_move)*/
    js.add_event_listener(info.window.title, .Mouse_Down, nil, callback_mouse_down)
    js.add_event_listener(info.window.title, .Mouse_Up, nil, callback_mouse_up)
    js.add_event_listener(info.window.title, .Scroll, nil, callback_wheel)
    js.add_event_listener(info.window.title, .Mouse_Move, nil, callback_mouse_move)
}

teardown :: proc() {

}

update_window :: proc() {

}

poll_event :: proc() -> (ev: event.Event, ok: bool) {
    if queue.len(_events) == 0 do return {}, false
    return queue.pop_front(&_events), true
}

get_backend_window :: proc() -> (window: rawptr) {
    return
}

