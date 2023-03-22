//+build js, wasi
package mmlow_js_wasmem

import "core:mem"
import "core:runtime"
import "core:fmt"
import "core:slice"
import "vendor:wasm/js"
import "core:intrinsics"



page_alloc :: proc(page_count: int) -> (data: []byte, err: mem.Allocator_Error) {
	prev_page_count := intrinsics.wasm_memory_grow(0, uintptr(page_count))
	if prev_page_count < 0 {
		return nil, .Out_Of_Memory
	}

	ptr := ([^]u8)(uintptr(prev_page_count) * PAGE_SIZE)
	return ptr[:page_count * PAGE_SIZE], nil
}
