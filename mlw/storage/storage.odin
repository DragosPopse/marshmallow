package mlw_storage

Key :: distinct u64

emplace :: proc {
    persistent_storage_emplace,
    dynamic_storage_emplace,
}

push :: proc {
    persistent_storage_push,
    dynamic_storage_push,
}

slice :: proc {
    persistent_storage_slice,
    dynamic_storage_slice,
}

get_ptr :: proc {
    persistent_storage_get_ptr,
    dynamic_storage_get_ptr,
}

get_copy :: proc {
    persistent_storage_get_copy,
    dynamic_storage_get_copy,
}

remove :: proc {
    dynamic_storage_remove,
}

remove_pending :: proc {
    dynamic_storage_remove_pending,
}