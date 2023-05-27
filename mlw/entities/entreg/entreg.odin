package mlw_entreg

import "core:fmt"

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
            last_packed := count - 1
            append(&free_list, packed[i])
            deleted_entity := packed[i]
            moved_entity := packed[last_packed]
            //fmt.printf("packed[%v](%v) = packed[%v](%v)\n", i, packed[deleted_entity], last_packed, packed[moved_entity])
            packed[i] = packed[last_packed]
            //fmt.printf("entities[%v](%v) = entities[%v](%v)\n", i, entities[deleted_entity], last_packed, entities[moved_entity])
            entities[i] = entities[last_packed]
            pending_destroy[i] = false
            //fmt.printf("pending_destroy[%v](%v) = pending_destroy[%v](%v)\n", i, pending_destroy[deleted_entity], last_packed, pending_destroy[moved_entity])
            pending_destroy[i] = pending_destroy[last_packed]
            //fmt.printf("sparse[%v](%v) = sparse[%v](%v)\n", deleted_entity, sparse[deleted_entity], moved_entity, sparse[moved_entity])
            //sparse[deleted_entity] = sparse[moved_entity]
            sparse[moved_entity] = sparse[deleted_entity]
            //fmt.printf("\n")
            //sparse[moved_entity] = -1 // ?
            //
            destroyed_count += 1
            count -= 1
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
        fmt.printf("Creating entity with next: %v\n", entity)
    } else {
        entity = pop(&free_list) // This might be the problemo
        fmt.printf("Creating entity with free list: %v\n", entity)
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
    assert(pos < count, "Cannot find entity.")
    packed[pos] = packed[last]
    sparse[entity] = sparse[last]

    count -= 1
    */
    pos := sparse[entity]
    fmt.assertf(pos < count, "Cannot find entity %v at position %v. Count: %v.", entity, pos, count) // This assert could be wrongm, or I'm setting things up bad
    pending_destroy[pos] = true
    fmt.printf("Marking entity %v at position %v for destroy\n", entity, pos)
}

find :: proc(reg: ^Registry($SIZE, $Entity_Type), entity: Entity) -> (val: ^Entity_Type) {
    using reg
    pos := sparse[entity]
    assert(pos < count, "Cannot find entity.")
    val = &entities[pos]
    return val
}