package highland_gfx_command

Command_Buffer :: struct {
    list: [dynamic]Command,
}

make_command_buffer :: proc(allocator := context.allocator) -> (buf: Command_Buffer) {
    buf.list = make([dynamic]Command, allocator)
    return 
}

delete_command_buffer :: proc(buf: Command_Buffer) {
    delete(buf.list)
}

clear_command_buffer :: proc(buf: ^Command_Buffer) {
    clear(&buf.list)
}

push_command :: proc(buf: ^Command_Buffer, cmd: Command) {
    append(&buf.list, cmd)
}