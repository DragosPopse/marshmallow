package mlw_random

import "../../math"
import cmath "core:math"
import crand "core:math/rand"

Xorshift64 :: struct {
    state: u64,
}

xorshift64_generate :: proc(state: rawptr) -> u64 {
    state := cast(^Xorshift64)state
    state.state ~= state.state << 13
    state.state ~= state.state >> 7
    state.state ~= state.state << 17
    return cast(u64)state.state
}

xorshift64_seed :: proc(state: rawptr, seed: u64) {
    state := cast(^Xorshift64)state
    seed := seed if seed != 0 else 1
    state.state = cast(u64)seed
}

xorshift64_generator :: proc(state: ^Xorshift64) -> (g: Generator) {
    return #force_inline generator(state, xorshift64_generate, xorshift64_seed)
}