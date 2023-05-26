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
    packed: [SIZE]Entity,
    entities: [SIZE]Entity_Type,
    pending_destroy: [SIZE]bool,
    free_list: [dynamic]Entity,
    count: int,
}

slice :: proc(reg: ^Registry($SIZE, $Entity_Type)) -> (entities: []Entity, values: []Entity_Type) {
    return reg.packed[:reg.count], reg.entities[:reg.count]
}

remove_pending_destroy :: proc(reg: ^Registry($SIZE, $Entity_Type)) -> (destroyed_count: int) {
    using reg
    for i := 0; i < count; {
        if pending_destroy[i] {
            last := count - 1
            entity := packed[i] // This good? If yes, we can simplify this
            pos := sparse[entity]
            packed[pos] = packed[last]
            entities[pos] = entities[last]
            sparse[entity] = sparse[packed[pos]] // this could be wrong?
            pending_destroy[i] = false
            pending_destroy[i] = pending_destroy[last]
            count -= 1
            destroyed_count += 1
            append(&free_list, packed[i])
            continue
        } else {
            i += 1
        }
    }
    return destroyed_count
}

create :: proc(reg: ^Registry($SIZE, $Entity_Type)) -> (entity: Entity) {
    using reg
    if len(free_list) == 0 {
        entity = next_entity
        next_entity += 1
    } else {
        entity = pop(&free_list)
    }
    
    val_pos := count
    packed[val_pos] = entity
    sparse[entity] = val_pos
    count += 1 
    return entity
}

destroy :: proc(reg: ^Registry($SIZE, $Entity_Type), entity: Entity) {
    using reg
    /*
    last := count - 1
    pos := sparse[entity]
    asset(pos < count, "Cannot find entity.")
    packed[pos] = packed[last]
    sparse[entity] = sparse[last]

    count -= 1
    */
    pos := sparse[entity]
    assert(pos < count, "Cannot find entity.")
    pending_destroy[pos] = true
}

find :: proc(reg: ^Registry($SIZE, $Entity_Type), entity: Entity) -> (val: ^Entity_Type) {
    using reg
    pos := sparse[entity]
    assert(pos < count, "Cannot find entity.")
    val = &entities[pos]
    return val
}