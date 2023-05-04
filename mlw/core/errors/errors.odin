package mlw_errors
import "core:strings"

// Note(Dragos): end user will need to know the error strings of each API, that's not necesarly nice

Error :: struct {
    type: string,
    message: string,
}

error :: proc(type, message: string) -> (err: Error) {
    err.type = strings.clone(type, context.temp_allocator)
    err.message = strings.clone(message, context.temp_allocator)
    return err
}