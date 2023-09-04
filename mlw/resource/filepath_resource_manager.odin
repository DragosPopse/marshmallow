package mlw_resource

// Note(Dragos): I'm still not entirely happy with this...

import "core:mem"
import "core:runtime"
import "core:path/filepath"
import "core:strings"

LOADER_DEFAULT_FILEPATH_ARENA_SIZE :: 256 * 300 // around 300 filepaths

Loader :: struct($Resource: typeid) {
    arena_backing: []byte,
    filepath_arena: mem.Arena,
    filepath_allocator: mem.Allocator,
    allocator: mem.Allocator,
    resources: map[string]Resource,
    free_proc: proc(resource: ^Resource),
    load_proc: proc(path: string) -> Resource,
}

loader_init :: proc(loader: ^Loader($Resource), allocator: mem.Allocator, load_proc: proc(path: string) -> Resource, free_proc: proc(r: ^Resource), filepath_arena_size := LOADER_DEFAULT_FILEPATH_ARENA_SIZE) {
    loader.arena_backing = make([]byte, filepath_arena_size, allocator)
    mem.arena_init(&loader.filepath_arena, loader.arena_backing)
    loader.allocator = allocator
    loader.filepath_allocator = mem.arena_allocator(&loader.filepath_arena)
    loader.load_proc = load_proc
    loader.free_proc = free_proc
    {
        context.allocator = loader.allocator
        loader.resources = make(map[string]Resource)
    }
}

loader_destroy :: proc(loader: ^Loader($Resource)) {
    unimplemented()
}

loader_load :: proc(loader: ^Loader($Resource), path: string) -> Resource {
    fullpath, ok := filepath.abs(path, context.temp_allocator)
    assert(ok, "Fullpath creation failed")
    assert(!(fullpath in loader.resources), "Resource is already loaded.")
    fullpath = strings.clone(fullpath, loader.filepath_allocator) // make it official
    res := map_insert(&loader.resources, fullpath, loader.load_proc(fullpath))
    return res^
}

loader_get :: proc(loader: ^Loader($Resource), path: string) -> Resource {
    fullpath, ok := filepath.abs(path, context.temp_allocator)
    assert(ok, "Fullpath creation failed")
    assert(fullpath in loader.resources, "Resource not found.")
    return loader.resources[fullpath] 
}

loader_load_or_get :: proc(loader: ^Loader($Resource), path: string) -> Resource {
    fullpath, ok := filepath.abs(path, context.temp_allocator)
    assert(ok, "Fullpath creation failed")
    if fullpath in loader.resources {
        return loader_get(loader, path)
    }
    return loader_load(loader, path) // this entire thing is slow, but it will do for now
}

loader_free_all :: proc(loader: ^Loader($Resource)) {
    for k, res in &loader.resources {
        loader.free_proc(&res)
    }
    clear_map(&loader.resources)
    free_all(loader.filepath_allocator)
}