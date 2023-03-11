package main

import "core:fmt"
import "core:mem"
import "../../mlw/core"
import "../../mlw/gpu"
import "../../mlw/image"
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
    center: math.Vec3f,
}

default_noise :: proc() -> (noise: Noise) {
    noise.seed = 10
    noise.strength = 1
    noise.roughness = 1
    noise.center = {0, 0, 0}
    return noise
}

evaluate_noise :: proc(noise: Noise, point: math.Vec3f) -> (value: f32) {
	using noise
	value = f32(cnoise.noise_3d_improve_xy(cast(i64)seed, linalg.to_f64(point * roughness + center)) + 1) * 0.5
	return value * strength
}