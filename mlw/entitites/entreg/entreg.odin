package mlw_entreg

Entity :: distinct int

Entity_Storage :: struct($Entity_Type: typeid) {
    info: Entity_Info,
    entity: Entity_Type,
}

// This entire goof is O(N) everything, but we'll see how it behaves in practice
Registry :: struct($SIZE: int, $Entity_Type: typeid) {
    next_entity: Entity,
    sparse: [SIZE]int,
    packed: [SIZE]Entity_Type,
    packed_len: int,
}

create :: proc(registry: ^Registry($Entity_Type)) -> (entity: Entity) {
    using registry
    entity = next_entity
    next_entity += 1
    val_pos := packed_len
    packed_len += 1
    sparse[entity] = val_pos
    return entity
}

destroy :: proc(registry: ^Registry($Entity_Type), entity: Entity) {
    using registry
    
    last := packed_len - 1
    packed[sparse[entity]] = packed[last]
    sparse[element] = sparse[last]

    packed_len -= 1
}

find :: proc(registry: ^Registry($Entity_Type), entity: Entity) -> (val: ^Entity_Type) {
    using registry
    pos := sparse[entity]
    assert(pos < packed_len, "Cannot find entity.")
    val = &packed[pos]
    return val
}