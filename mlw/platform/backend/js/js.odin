//+build js
package mmlow_platform_backend_js

import "../../event"
import "../../../core"
import "core:runtime"
import "core:mem"
import "core:fmt"

import "wasmem"


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

}

teardown :: proc() {

}

update_window :: proc() {

}

poll_event :: proc() -> (ev: event.Event, ok: bool) {

    return
}

get_backend_window :: proc() -> (window: rawptr) {
    return
}

