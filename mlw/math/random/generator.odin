package mlw_random

import "../../math"
import cmath "core:math"
import crand "core:math/rand"

//Note(Dragos): Should the API return an u32 instead? Aka the smallest possible generable number

Generator_Proc :: #type proc(state: rawptr) -> u64

Seed_Proc :: #type proc(state: rawptr, seed: u64)

Generator :: struct {
    state: rawptr,
    generator_proc: Generator_Proc,
    seed_proc: Seed_Proc,
}

generator :: proc(state: ^$T, generator_proc: Generator_Proc, seed_proc: Seed_Proc) -> (g: Generator) {
    g.state = state
    g.generator_proc = generator_proc
    g.seed_proc = seed_proc
    return g
}

generate :: proc(rng: ^Generator) -> u64 {
    return rng.generator_proc(rng.state)
}

seed :: proc(rng: ^Generator, seed: u64) {
    rng.seed_proc(rng.state, seed)
}

