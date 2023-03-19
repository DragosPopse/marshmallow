package mmlow_js_wasmem

import "core:mem"
import "core:runtime"
import "core:fmt"
import "core:slice"
import "vendor:wasm/js"

PAGE_SIZE :: 64 * 1024

// Adapted from https://www.gingerbill.org/article/2021/11/30/memory-allocation-strategies-005/

Free_List_Alloc_Header :: struct {
    block_size: int,
    padding: int,
}

Free_List_Node :: struct {
    next: ^Free_List_Node,
    block_size: int,
}

Placement_Policy :: enum {
    Find_First,
    Find_Best,
}

Free_List :: struct {
    data: []byte,
    used: int,
    head: ^Free_List_Node,
    policy: Placement_Policy,
}

free_list_node_insert :: proc(fl: ^Free_List, prev_node, new_node: ^Free_List_Node) {
    if prev_node == nil {
        if fl.head != nil {
            new_node.next = fl.head
        } else {
            fl.head = new_node
        }
    } else {
        if prev_node.next == nil {
            prev_node.next = new_node
            new_node.next = nil
        } else {
            new_node.next = prev_node.next
            prev_node.next = new_node
        }
    }
}

free_list_node_remove :: proc(fl: ^Free_List, prev_node, del_node: ^Free_List_Node) {
    if prev_node == nil {
        fl.head = del_node.next
    } else {
        prev_node.next = del_node.next
    }
}

calc_padding_with_header :: proc(ptr: uintptr, alignment, header_size: int) -> (padding: int) {
    p, a, modulo, needed_space, pad: uintptr
    p = ptr
    a = cast(uintptr)alignment
    modulo = p & (a - 1)
    if modulo != 0 {
        pad = a - modulo
    }

    needed_space = cast(uintptr)header_size
    if pad < needed_space {
        needed_space -= pad
        if (needed_space & (a - 1)) != 0 {
            pad += a * (1 + needed_space / a)
        } else {
            pad += a * (needed_space / a)
        }
    }

    return cast(int)pad
}

free_list_init :: proc "contextless" (fl: ^Free_List, data: []byte) {
    fl.policy = .Find_First
    //TODO(dragos): do some page alloc in here
    fl.data = data
    free_list_free_all(fl)
}

free_list_free_all :: proc "contextless" (fl: ^Free_List) {
    fl.used = 0
    first_node := cast(^Free_List_Node)raw_data(fl.data)
    first_node.block_size = len(fl.data)
    first_node.next = nil
    fl.head = first_node
}

free_list_find_first :: proc(fl: ^Free_List, size, alignment: int) -> (node: ^Free_List_Node, padding: int, prev_node: ^Free_List_Node) {
    node = fl.head
    fmt.printf("Head: %v\n", node)
    for node != nil {
        padding = calc_padding_with_header(cast(uintptr)node, alignment, size_of(Free_List_Alloc_Header))
        required_space := size + padding
        //fmt.printf("pad, align, size: %v %v %v\n", padding, alignment, size)
        //fmt.printf("block_size, required_space: %v %v %v\n", node.block_size, required_space)
        if node.block_size >= required_space do break
        prev_node = node
        node = node.next
    }
    return node, padding, prev_node
}

// Note(Dragos): There is a bug in this one
free_list_find_best :: proc(fl: ^Free_List, size, alignment: int) -> (best_node: ^Free_List_Node, padding: int, prev_node: ^Free_List_Node) {
    smallest_diff := ~uint(0)
    node := fl.head

    for node != nil {
        padding = calc_padding_with_header(cast(uintptr)node, alignment, size_of(Free_List_Alloc_Header))
        //fmt.printf("pad, align, size: %v %v %v\n", padding, alignment, size)
        required_space := size + padding
        //fmt.printf("block_size, required_space, smallest_diff: %v %v\n", node.block_size, required_space, smallest_diff)
        if node.block_size >= required_space && uint(node.block_size - required_space) < smallest_diff {
            best_node = node
            smallest_diff = uint(node.block_size - required_space)
        }
        prev_node = node
        node = node.next
    }

    return best_node, padding, prev_node
}

free_list_find :: proc(fl: ^Free_List, size, alignment: int) -> (best_node: ^Free_List_Node, padding: int, prev_node: ^Free_List_Node) {
    if fl.policy == .Find_Best do return free_list_find_best(fl, size, alignment)
    else do return free_list_find_first(fl, size, alignment)
}


free_list_alloc :: proc(fl: ^Free_List, size, alignment: int) -> (data: []byte, err: mem.Allocator_Error) {
    size := size
    alignment := alignment

    if size < size_of(Free_List_Node) do size = size_of(Free_List_Node)
    if alignment < 8 do alignment = 8

    node, padding, prev_node := free_list_find(fl, size, alignment)
    if node == nil {
        fmt.printf("Out of memory. We shouldn't be here.\n")
        return nil, .Out_Of_Memory
    }

    alignment_padding := padding - size_of(Free_List_Alloc_Header)
    required_space := size + padding
    remaining := node.block_size - required_space
    //fmt.printf("PRE Head, node, prev_node: %v %v %v\n", fl.head, node, prev_node)
    if remaining > 0 {
        new_node := cast(^Free_List_Node)(uintptr(node) + uintptr(required_space))
        new_node.block_size = remaining
        free_list_node_insert(fl, node, new_node)
    }
    free_list_node_remove(fl, prev_node, node)
    //fmt.printf("POST Head, node, prev_node: %v %v %v\n", fl.head, node, prev_node)
    header_ptr := cast(^Free_List_Alloc_Header)(uintptr(node) + uintptr(alignment_padding))
    header_ptr.block_size = required_space
    header_ptr.padding = alignment_padding
    
    fl.used += required_space

    ptr := ([^]byte)(uintptr(header_ptr) + size_of(Free_List_Alloc_Header))
    //fmt.printf("PTR: %v\n", uintptr(ptr))
    return slice.from_ptr(ptr, required_space), .None
}

free_list_free :: proc(fl: ^Free_List, ptr: rawptr) {
    if ptr == nil do return
    header := cast(^Free_List_Alloc_Header)(uintptr(ptr) - size_of(Free_List_Alloc_Header))
    free_node := cast(^Free_List_Node)header
    free_node.block_size = header.block_size + header.padding
    free_node.next = nil
    
    node := fl.head
    prev_node: ^Free_List_Node
    for node != nil {
        if uintptr(ptr) < uintptr(node) {
            free_list_node_insert(fl, prev_node, free_node)
            break
        }
        prev_node = node
        node = node.next
    }
    fl.used -= free_node.block_size
    free_list_merge_nodes(fl, prev_node, free_node)
}

free_list_merge_nodes :: proc(fl: ^Free_List, prev_node, free_node: ^Free_List_Node) {
    if prev_node == nil do return

    if free_node.next != nil && rawptr(uintptr(free_node) + uintptr(free_node.block_size)) == free_node.next {
        free_node.block_size += free_node.next.block_size
        free_list_node_remove(fl, free_node, free_node.next)
    }

    if prev_node.next != nil && rawptr(uintptr(prev_node) + uintptr(prev_node.block_size)) == free_node {
        prev_node.block_size += free_node.block_size
        free_list_node_remove(fl, prev_node, free_node)
    }
}

free_list_allocator :: proc "contextless" (fl: ^Free_List) -> (allocator: mem.Allocator) {
    allocator.procedure = free_list_allocator_proc
    allocator.data = fl
    return allocator
}

free_list_allocator_proc :: proc(allocator_data: rawptr, mode: mem.Allocator_Mode, 
        size, alignment: int, 
        old_memory: rawptr, old_size: int, 
        location := #caller_location) -> ([]byte, mem.Allocator_Error) {
    fl := cast(^Free_List)allocator_data
    switch mode {
        case .Alloc: {
            return free_list_alloc(fl, size, alignment)
        }

        case .Alloc_Non_Zeroed: {
            return free_list_alloc(fl, size, alignment)
        }

        case .Free: {
            free_list_free(fl, old_memory)
            return nil, .None
        }

        case .Free_All: {
            free_list_free_all(fl)
            return nil, .None
        }

        case .Resize: {
            //fmt.printf("RESIZE CALLED AT LOCATION %v\n", location)
            return nil, .Mode_Not_Implemented
        }

        case .Query_Features: {
            set := (^mem.Allocator_Mode_Set)(old_memory)
			if set != nil {
				set^ = {.Alloc, .Alloc_Non_Zeroed, .Free, .Free_All, .Query_Features}
			}
            return nil, .None
        }

        case .Query_Info: {
            return nil, .Mode_Not_Implemented
        }
    }

    return nil, nil
}