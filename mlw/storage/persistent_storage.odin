package mlw_storage

/*
    Storage Features:
    - fast lookup
    - fast element push
    - get_ptr stability
    - no insertion
    - no deletion
*/
Persistent_Storage :: struct($SIZE: int, $T: typeid) {
    data: [SIZE]T,
    length: int,
}

persistent_storage_slice :: proc(store: ^Persistent_Storage($SIZE, $T)) -> (slice: []T) {
    return store.data[:store.length]
}

// Returns the next uninitialized element in the storage
persistent_storage_emplace :: proc(store: ^Persistent_Storage($SIZE, $T)) -> (val: ^T, key: Key) {
    assert(store.length < SIZE, "Maximum capacity reached for Persistent_Storage.")
    val = &store.data[store.length]
    key = cast(Key)store.length
    store.length += 1
    return val, key
}

// Push an element and return it
persistent_storage_push :: proc(store: ^Persistent_Storage($SIZE, $T), val: T) -> (result: ^T, key: Key) {
    assert(store.length < SIZE, "Maximum capacity reached for Persistent_Storage.")
    result = &store.data[store.length]
    key = cast(Key)store.length
    store.length += 1
    result^ = val^
    return result, key
}

persistent_storage_get_ptr :: proc(store: ^Persistent_Storage($SIZE, $T), key: Key) -> (val: ^T) {
    index := cast(int)key
    assert(index < length, "Invalid key.")
    return &store.data[index]
}

persistent_storage_get_copy :: proc(store: ^Persistent_Storage($SIZE, $T), key: Key) -> (val: T) {
    index := cast(int)key
    assert(index < length, "Invalid key.")
    return store.data[index]
}