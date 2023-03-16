//+build ignore
package main

import "core:fmt"
import "core:mem"
import "../../mlw/core"
import "../../mlw/gpu"
import "../../mlw/math"
import "../../mlw/platform"
import linalg "core:math/linalg"
import "core:slice"
import mu "vendor:microui"
import mu_mlw "../../mlw/third/microui"
import "../../mlw/platform/event"
import cnoise "core:math/noise"


Noise :: struct {
	seed: int,
    strength: f32,
    roughness: f32,
    base_roughness: f32,
    layers_count: int,
    persistence: f32,
    center: math.Vec3f,
    min_value: f32,
}

default_noise :: proc() -> (noise: Noise) {
    noise.seed = 10
    noise.strength = 0.38
    noise.roughness = 2
    noise.center = {0, 0, 0}
    noise.base_roughness = 0.5
    noise.layers_count = 5
    noise.persistence = 0.5
    noise.min_value = 1
    return noise
}

evaluate_noise :: proc(noise: Noise, point: math.Vec3f) -> (value: f32) {
	using noise
    frequency := base_roughness
    amplitude: f32 = 1
    for i in 0..<layers_count {
        v := cast(f32)cnoise.noise_3d_improve_xy(cast(i64)seed, linalg.to_f64(point * frequency + center))
        value += (v + 1) * 0.5 * amplitude
        frequency *= roughness
        amplitude *= persistence // forgot to use this
    }
    value = max(0, value - min_value)
	return value * strength
}