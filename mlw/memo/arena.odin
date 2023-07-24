package mlw_memory

// Utilities to make arenas nicer to use


import "core:mem"
import "core:runtime"
import "core:mem/virtual"




Arena :: struct {
    #subtype allocator: mem.Allocator,
    arena: virtual.Arena,
}

// Temporary Arena
TArena :: virtual.Arena_Temp
tarena_begin :: proc(arena: ^Arena, loc := #caller_location) -> TArena {
    return virtual.arena_temp_begin(&arena.arena, loc)
}
tarena_end :: virtual.arena_temp_end

SArena :: struct($SIZE: int) {
    using _: Arena,
    buffer: [SIZE]byte,
}

VArena :: struct {
    using _: Arena,
}


arena_from_slice :: proc(data: []byte) -> (arena: Arena) {
    err := virtual.arena_init_buffer(&arena.arena, data)
    assert(err == nil, "Arena creation failure")
    arena.allocator = virtual.arena_allocator(&arena.arena)
    return arena
}

varena_init :: proc(arena: ^VArena, reserved: uint = virtual.DEFAULT_ARENA_GROWING_MINIMUM_BLOCK_SIZE) {
    err := virtual.arena_init_growing(&arena.arena, reserved)
    assert(err == nil, "Virtual arena creation failure")
}

varena_destroy :: proc(arena: ^VArena) {
    virtual.arena_destroy(&arena.arena)
}

sarena_init :: proc(arena: ^SArena($SIZE)) {
    err := virtual.arena_init_buffer(&arena.arena, data)
    assert(err == nil, "Arena creation failure")
    arena.allocator = virtual.arena_allocator(&arena.arena)
}

varena :: proc(reserved: uint = virtual.DEFAULT_ARENA_GROWING_MINIMUM_BLOCK_SIZE) -> (arena: VArena) {
    varena_init(&arena)
    return arena
}

sarena :: proc($SIZE: int) -> (arena: SArena(SIZE)) {
    sarena_init(&arena)
    return arena
}

