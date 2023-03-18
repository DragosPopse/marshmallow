package mmlow_js_wasmem

import "core:mem"
import "core:runtime"
import "vendor:wasm/js"

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
    data: rawptr,
    size: int,
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
        fl.head = prev_node
    } else {
        prev_node.next = del_node.next
    }
}

calc_padding_with_header :: proc(ptr: uintptr, alignment, header_size: int) -> int {
    return 0
}

free_list_init :: proc(fl: ^Free_List) {
    fl.policy = .Find_Best
    //TODO(dragos): do some page alloc in here
    free_list_free_all(fl)
}

free_list_free_all :: proc(fl: ^Free_List) {
    fl.used = 0
    first_node := cast(^Free_List_Node)fl.data
    first_node.block_size = fl.size
    first_node.next = nil
    fl.head = first_node
}

free_list_find_first :: proc(fl: ^Free_List, size, alignment: int) -> (node: ^Free_List_Node, padding: int, prev_node: ^Free_List_Node) {
    node = fl.head
    for node != nil {
        padding = calc_padding_with_header(cast(uintptr)node, alignment, size_of(Free_List_Alloc_Header))
        required_space := size + padding
        if node.block_size >= required_space do break
        prev_node = node
        node = node.next
    }
    return node, padding, prev_node
}

free_list_find_best :: proc(fl: ^Free_List, size, alignment: int) -> (best_node: ^Free_List_Node, padding: int, prev_node: ^Free_List_Node) {
    smallest_diff := ~uint(0)
    node := fl.head

    for node != nil {
        padding = calc_padding_with_header(cast(uintptr)node, alignment, size_of(Free_List_Alloc_Header))
        required_space := size + padding
        if node.block_size >= required_space && uint(node.block_size - required_space) < smallest_diff {
            best_node = node
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

free_list_alloc :: proc(fl: ^Free_List, size, alignment: int) -> (data: rawptr) {
    size := size
    alignment := alignment

    if size < size_of(Free_List_Node) do size = size_of(Free_List_Node)
    if alignment < 8 do alignment = 8

    node, padding, prev_node := free_list_find(fl, size, alignment)
    if node == nil {
        // TODO(dragos): more pages pls
    }

    alignment_padding := padding - size_of(Free_List_Alloc_Header)
    required_space := size + padding
    remaining := node.block_size - required_space

    if remaining > 0 {
        new_node := cast(^Free_List_Node)(uintptr(node) + uintptr(required_space))
        new_node.block_size = remaining
        free_list_node_insert(fl, node, new_node)
    }
    free_list_node_remove(fl, prev_node, node)
    header_ptr := cast(^Free_List_Alloc_Header)(uintptr(node) + uintptr(alignment_padding))
    header_ptr.block_size = required_space
    header_ptr.padding = alignment_padding
    
    fl.used += required_space

    return rawptr(uintptr(header_ptr) + size_of(Free_List_Alloc_Header))
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
    if free_node.next != nil && rawptr(uintptr(free_node) + uintptr(free_node.block_size)) == free_node.next {
        free_node.block_size += free_node.next.block_size
        free_list_node_remove(fl, free_node, free_node.next)
    }

    if prev_node.next != nil && rawptr(uintptr(prev_node) + uintptr(prev_node.block_size)) == free_node {
        prev_node.block_size += free_node.block_size
        free_list_node_remove(fl, prev_node, free_node)
    }
}