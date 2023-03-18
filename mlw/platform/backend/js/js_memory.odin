//+build ignore
package mmlow_platform_backend_js

import "core:runtime"
import "core:mem"
import "vendor:wasm/js"
import "core:slice"
import "core:fmt"
import "core:intrinsics"

import "wasmem"





@(init)
_init_default_context :: proc "contextless" () {
    context = runtime.default_context()
    _default_context = runtime.default_context()
    wasm_alloc_init(&allocator_data)
    _default_context.allocator = wasm_allocator()
    err := mem.scratch_allocator_init(&scratch, 100 * mem.Megabyte, _default_context.allocator)
    _default_context.temp_allocator = mem.scratch_allocator(&scratch)
    fmt.assertf(err == .None, "Scratch allocator failed with %v\n", err)
}

default_context :: proc "contextless" () -> (ctx: runtime.Context) {
    return _default_context
}

@(export, link_name = "odin_context_ptr")
odin_context_ptr :: proc "contextless"() -> (^runtime.Context) {
    return &_default_context
}

MAGIC_HEADER :: 0xFEFE

// NOTE(matthew): wasm is 32-bit by default, but has a 64-bit extension

Header :: struct {
    fefe: u16,
    size: int,
    next: ^Header,
}

Wasm_Allocator_Data :: struct {
    buffer: []byte,
}



wasm_page_resize :: proc(wasm_data: ^Wasm_Allocator_Data, page_count: int) -> (err: mem.Allocator_Error) {
	prev_page_count := intrinsics.wasm_memory_grow(0, uintptr(page_count))
	if prev_page_count < 0 {
		return .Out_Of_Memory
	}

	ptr :[^]byte = cast([^]byte)(&wasm_data.buffer[0])
    wasm_data.buffer = ptr[:(prev_page_count + page_count) * js.PAGE_SIZE]
    heap := cast(^Header)&wasm_data.buffer[0]
    heap.size += page_count * js.PAGE_SIZE
	return .None
}

wasm_alloc_init :: proc(data: ^Wasm_Allocator_Data) {
    data.buffer, _ = js.page_alloc(1)
    header := cast(^Header)&data.buffer[0]
    header.fefe = MAGIC_HEADER 
    header.size = js.PAGE_SIZE - size_of(Header)
}


wasm_alloc :: proc(data: ^Wasm_Allocator_Data, size: int, alignment: int) -> (buffer: []byte, err: mem.Allocator_Error) {
    // TODO(matthew): handle alignment
    fmt.printf("wasm_alloc: %v %v\n", size, alignment)
    size := size
    
    
    alloc_size := size + size_of(Header)
    
    block_header := cast(^Header)&data.buffer[0]
    fmt.printf("block_header: %#v\n", block_header)
    for block_header != nil && block_header.size < alloc_size {
        block_header = block_header.next
        fmt.printf("for block_header: %#v\n", block_header)
    }

    if block_header == nil { 
        pages_to_alloc := ((size + size_of(Header)) / js.PAGE_SIZE) + 1
        fmt.printf("Pages to alloc: %v\n", pages_to_alloc)
        if err = wasm_page_resize(data, pages_to_alloc); err != .None {
            return nil, err
        }
        block_header = cast(^Header)&data.buffer[0]
    }

    fmt.printf("FINAL block_header: %#v\n", block_header)
    
    block_ptr := uintptr(block_header) + size_of(Header)

    block := slice.from_ptr(cast([^]byte)block_ptr, block_header.size)
   
    block_start := block_header.size - alloc_size

    fmt.printf("block_start, header_size: %v %v\n", block_start, block_header.size)
    fmt.printf("alloc_size %v\n", alloc_size)
    allocated_data := block[block_start:block_start + alloc_size]
    
    block_header.size -= alloc_size

    header := cast(^Header)raw_data(allocated_data[0:size_of(Header)])
    buffer = allocated_data[size_of(Header):]
    header.size = size
    header.fefe = MAGIC_HEADER
    fmt.printf("Buffer size: %v", len(buffer))
    fmt.assertf(len(buffer) == size, "Buffer size mismatch: %v %v", len(buffer), alloc_size)
    
    return
}

wasm_free :: proc(data: ^Wasm_Allocator_Data, ptr: rawptr) -> (err: mem.Allocator_Error) {
    header := cast(^Header)(uintptr(ptr) - size_of(Header))
    assert(header.fefe == MAGIC_HEADER)

    block_header := cast(^Header)&data.buffer[0]
    for block_header.next != nil {
        block_header = block_header.next
    }

    block_header.next = header

    return
}

wasm_allocator :: proc() -> (allocator: mem.Allocator) {
    allocator.procedure = allocator_proc
    allocator.data = &allocator_data
    return allocator
}

allocator_proc :: proc(allocator_data: rawptr, mode: mem.Allocator_Mode, 
        size, alignment: int, 
        old_memory: rawptr, old_size: int, 
        location := #caller_location) -> ([]byte, mem.Allocator_Error) {
    data := cast(^Wasm_Allocator_Data)allocator_data
    switch mode {
        case .Alloc: {
            return wasm_alloc(data, size, alignment)
        }

        case .Alloc_Non_Zeroed: {
            return wasm_alloc(data, size, alignment)
        }

        case .Free: {
            return nil, wasm_free(data, old_memory)
        }

        case .Free_All: {
            heap := cast(^Header)&data.buffer[0]
            heap.next = nil
            heap.size = len(data.buffer)
            return nil, .None
        }

        case .Query_Features: {
            set := (^mem.Allocator_Mode_Set)(old_memory)
			if set != nil {
				set^ = {.Alloc, .Alloc_Non_Zeroed, .Free, .Free_All, .Query_Features}
			}
            return nil, .None
        }

        case .Query_Info, .Resize: {
            return nil, .Mode_Not_Implemented
        }
    }

    return nil, nil
}