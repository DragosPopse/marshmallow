//+build !js
package mmlow_js_wasmem

import "core:mem"


page_alloc :: proc(page_count: int) -> (data: []byte, err: mem.Allocator_Error) {
	panic("wasmem.page_alloc not supported by non js target")
}
