package mlw_functors

import "core:mem"

Functor_Proc :: #type proc(data: rawptr, args: ..any)

STORAGE_SIZE :: 64 * size_of(int)

Functor :: struct {
    storage: [STORAGE_SIZE]byte,
    data: rawptr,
    data_size: int,
    data_type: typeid,
    callback: Functor_Proc,
}

create_from_type :: proc($data_type: typeid, callback: Functor_Proc) -> (functor: Functor) {
    arena: mem.Arena
    mem.arena_init(&arena, functor.storage[:])
    context.allocator = mem.arena_allocator(&arena)

    data, err := mem.alloc_bytes(size_of(data_type), align_of(data_type))
    assert(err == nil, "Allocator error.")
    
    functor.data = raw_data(data)
    functor.callback = callback
    functor.data_type = data_type
    functor.data_size = size_of(data_type)
    return functor
}

data :: proc(functor: ^Functor, data: $T) {
    assert(functor.data_type == T, "Data type mismatch")
    //src := mem.any_to_bytes(data)
    //mem.copy(functor.data, raw_data(src), len(src))
    d := cast(^T)functor.data
    d^ = data
}

call :: proc(functor: ^Functor, args: ..any) {
    functor.callback(functor.data, args)
}