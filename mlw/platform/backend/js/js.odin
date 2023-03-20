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


WASM_MEMORY_PAGES :: #config(MLW_WASM_MEMORY_PAGES_CONFIG, 16384) // 1 GiB default

WASM_TEMP_ALLOCATOR_MB :: #config(MLW_WASM_TEMP_ALLOCATOR_MB, 4)


free_list: wasmem.Free_List
wasm_context: runtime.Context
scratch: mem.Scratch_Allocator

_temp_allocator_data: [WASM_TEMP_ALLOCATOR_MB * mem.Megabyte]byte
_temp_allocator_arena: mem.Arena

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
    mem.arena_init(&_temp_allocator_arena, _temp_allocator_data[:])
    
    wasm_context.allocator = wasmem.free_list_allocator(&free_list)
    wasm_context.temp_allocator = mem.arena_allocator(&_temp_allocator_arena)
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

