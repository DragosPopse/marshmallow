
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

Noise_Type :: enum {
    Simple,
    Rigid,
}

Noise :: struct {
    type: Noise_Type,

    // Common
	seed: int,
    strength: f32,
    roughness: f32,
    base_roughness: f32,
    layers_count: int,
    persistence: f32,
    center: math.Vec3f,
    min_value: f32,

    // Rigid
    weight_multiplier: f32,
}

Noise_Layer :: struct {
    noise: Noise,
    enabled: bool,
    use_first_layer_as_mask: bool,
}

noise_layer :: proc(noise: Noise) -> (layer: Noise_Layer) {
    layer.noise = noise
    layer.enabled = true
    return layer
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
    noise.weight_multiplier = 1
    return noise
}

evaluate_noise :: proc(noise: Noise, point: math.Vec3f) -> (value: f32) {
	switch noise.type {
        case .Simple: return evaluate_noise_simple(noise, point)
        case .Rigid: return evaluate_noise_rigid(noise, point)
    }
    return 1
}

evaluate_noise_simple :: proc(noise: Noise, point: math.Vec3f) -> (value: f32) {
	using noise
    frequency := base_roughness
    amplitude: f32 = 1
    first_layer_value := f32(0)
    
    for i in 0..<layers_count {
        v := cast(f32)cnoise.noise_3d_improve_xy(cast(i64)seed, linalg.to_f64(point * frequency + center))
        value += (v + 1) * 0.5 * amplitude
        frequency *= roughness
        amplitude *= persistence // forgot to use this
    }
    value = max(0, value - min_value)
	return value * strength
}

evaluate_noise_rigid :: proc(noise: Noise, point: math.Vec3f) -> (value: f32) {
	using noise
    frequency := base_roughness
    amplitude: f32 = 1
    first_layer_value := f32(0)
    weight: f32 = 1
    for i in 0..<layers_count {
        v := cast(f32)cnoise.noise_3d_improve_xy(cast(i64)seed, linalg.to_f64(point * frequency + center))
        v = 1 - abs(v)
        v *= v // square to make it more pronounced
        v *= weight
        weight = clamp(v * weight_multiplier, 0, 1)
        weight = v
        value += v * amplitude
        frequency *= roughness
        amplitude *= persistence // forgot to use this
    }
    value = max(0, value - min_value)
	return value * strength
}