package mlw_entreg

Entity :: distinct u64

Entity_Info :: struct {
    id: Entity,
    is_alive: bool,
    tag: Maybe(string),
}

Entity_Storage :: struct($Entity_Type: typeid) {
    info: Entity_Info,
    entity: Entity_Type,
}

// This entire goof is O(N) everything, but we'll see how it behaves in practice
Registry :: struct($Entity_Type: typeid) {
    next_id: Entity,
    entities: [dynamic]Entity_Storage(Entity_Type),
}

Iterator :: struct($Entity_Type: typeid) {
    registry: ^Registry(Entity_Type),
    index: int,
}

iterator :: proc(registry: ^Registry($Entity_Type)) -> Iterator(Entity_Type) {
    return Iterator(Entity_Type) {
        registry = registry,
        index = 0,
    }
}

next :: proc(iter: ^Iterator($Entity_Type)) -> (entity: ^Entity_Type, id: Entity, ok: bool) {
    if iter.index >= len(iter.registry.entities) do return
    #no_bounds_check e := &iter.registry.entities[iter.index]
    entity = &e.entity
    id = e.info.id
    ok = true
    iter.index += 1
    return entity, id, ok
}

create :: proc(registry: ^Registry($Entity_Type), tag: Maybe(string) = nil) -> (entity: ^Entity_Type, id: Entity) {
    id = registry.next_id
    registry.next_id += 1
    storage: Entity_Storage(Entity_Type)
    storage.info.id = id
    storage.info.is_alive = true
    storage.info.tag = tag
    location := append(&registry.entities, storage)
    entity = &registry.entities[location].entity
    return entity, id
}

destroy :: proc(registry: ^Registry($Entity_Type), id: Entity) {
    for entity, i in registry.entities {
        if entity.info.id == id {
            unordered_remove(&registry.entities, i)
            return
        }
    }
}

find :: proc(registry: ^Registry($Entity_Type), id: Entity) -> (entity: ^Entity_Type) {
    for entity, i in registry.entities {
        if entity.info.id == id {
            return &entity.entity
        }
    }
    return nil
}