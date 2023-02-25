package mmlow_imdraw

import "core:mem/virtual"
import "core:mem"


Command_Buffer :: struct {
    _arena: virtual.Arena,
    sprites: [dynamic]Command_Sprite,
    quads: [dynamic]Command_Quad,
    lines: [dynamic]Command_Line,
}

init_command_buffer_lists :: proc(buf: ^Command_Buffer, allocator: mem.Allocator) {
    buf.sprites = make([dynamic]Command_Sprite, allocator)
    buf.quads = make([dynamic]Command_Quad, allocator)
    buf.lines = make([dynamic]Command_Line, allocator)
    
}

make_command_buffer :: proc() -> (buf: Command_Buffer) {
    err := virtual.arena_init_growing(&buf._arena)
    assert(err == .None, "Virtual arena error.")
    allocator := virtual.arena_allocator(&buf._arena)
    init_command_buffer_lists(&buf, allocator)    
    return buf
}

delete_command_buffer :: proc(buf: ^Command_Buffer) {
    virtual.arena_destroy(&buf._arena)
}

clear_command_buffer :: proc(buf: ^Command_Buffer) {
    virtual.arena_free_all(&buf._arena)
    init_command_buffer_lists(buf, virtual.arena_allocator(&buf._arena))
}

push_sprite :: proc(buf: ^Command_Buffer, cmd: Command_Sprite) {
    append(&buf.sprites, cmd)
}

push_quad :: proc(buf: ^Command_Buffer, cmd: Command_Quad) {
    append(&buf.quads, cmd)
}

push_line :: proc(buf: ^Command_Buffer, cmd: Command_Line) {
    append(&buf.lines, cmd)
}

push_command :: proc {
    push_sprite,
    push_quad,
    push_line,
}