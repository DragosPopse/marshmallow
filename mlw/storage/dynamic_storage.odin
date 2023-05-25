package mlw_storage

/*
    Storage Features:
    - lookup
    - fast element push
    - pointer instability on element deletion
    - unordered
    - no insertion
    - fast element deletion
*/
Dynamic_Storage :: struct($SIZE: int, $T: typeid) {
    data: #soa [SIZE]Dynamic_Storage_Data(T),
    length: int,
    next_key: Key,
}

// Note(Dragos): Could we make these storages intrusive? 

Dynamic_Storage_Data :: struct($T: typeid) {
    key: Key,
    data: T,
    remove: bool,
}

// This is an unstable slice. Removing elements will invalidate it
dynamic_storage_slice :: proc(store: ^Dynamic_Storage($SIZE, $T)) -> (slice: []T) {
    return store.data.data[:store.length]
}

// Returns the next uninitialized element in the storage
dynamic_storage_emplace :: proc(store: ^Dynamic_Storage($SIZE, $T)) -> (val: ^T, key: Key) {
    key = store.next_key
    store.next_key += 1
    idx := store.length
    store.length += 1
    assert(store.length < SIZE, "Capacity reached for dynamic storage.")
    store.data[idx].key = key
    return &store.data[idx].data, key
}

// Push an element and return it
dynamic_storage_push :: proc(store: ^Dynamic_Storage($SIZE, $T), val: T) -> (result: ^T, key: Key) {
    key = store.next_key
    store.next_key += 1
    idx := store.length
    store.length += 1
    assert(store.length < SIZE, "Capacity reached for dynamic storage.")
    store.data[idx].key = key
    store.data[idx].data = val
    return &store.data[idx].data, key
}

// This can be made more performant with a sparse set data structure. Later.
dynamic_storage_get_ptr :: proc(store: ^Dynamic_Storage($SIZE, $T), key: Key) -> (val: ^T) {
    for elem, i in &store.data {
        if elem.key == key {
            return &store.data[i].data
        }
    }
    return
}

dynamic_storage_get_copy :: proc(store: ^Dynamic_Storage($SIZE, $T), key: Key) -> (val: T) {
    return dynamic_storage_get_ptr(store, key)^
}

// Note(Dragos): We can make the removal direct, and iterate only through iterators. The iterator can check if the length is changed and update accordingly
// Note(Dragos): Last comment won't work. 
// Make sure you call remove_all_pending at the end of the frame
dynamic_storage_remove :: proc(store: ^Dynamic_Storage($SIZE, $T), key: Key)  -> (removed_val: T) {
    data := store.data[:store.length]
    for elem, i in &data {
        if elem.key == key { // O(N), but decently fast because we soa this shit. 
            removed_val = elem.data
            elem.remove = true
            return removed_val
        }
    }
    return
}


dynamic_storage_remove_pending :: proc(store: ^Dynamic_Storage($SIZE, $T)) -> (removed_values: int) {
    for i := 0; i < store.length; /**/ {
        if store.data[i].remove {
            removed_values += 1
            store.data[i] = store.data[store.length - 1]
            store.length -= 1
            continue
        } else {
            i += 1
        }
    }
    return removed_values
}