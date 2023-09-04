package mlw_mathf

import "core:math"
import "core:math/linalg"

normalize :: linalg.normalize

vec2_magnitude :: proc(v: Vec2) -> f32 {
    return math.sqrt(v.x * v.x + v.y * v.y)
}

vec2_sqr_magnitude :: proc(v: Vec2) -> f32 {
    return v.x * v.x + v.y * v.y
}

vec2_slope :: proc(a, b: Vec2) -> f32 {
    return (b.y - a.y) / (b.x - a.x)
}