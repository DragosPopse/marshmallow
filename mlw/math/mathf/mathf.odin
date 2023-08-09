package mlw_mathf

import "core:math"
import "core:math/linalg"

Vec2 :: linalg.Vector2f32
Vec3 :: linalg.Vector3f32

Mat3 :: linalg.Matrix3f32
Mat4 :: linalg.Matrix4f32

Rad :: distinct f32
Deg :: distinct f32

DEG_PER_RAD :: math.DEG_PER_RAD
RAD_PER_DEG :: math.RAD_PER_DEG
PI :: math.PI
TAU :: math.TAU
INFINITY :: math.INF_F32


Angle :: union {
    Rad,
    Deg,
}

Rect :: struct {
    pos: Vec2,
    size: Vec2,
}

Circle :: struct {
    pos: Vec2,
    radius: f32,
}

magnitude :: proc {
    vec2_magnitude,
}

sqr_magnitude :: proc {
    vec2_sqr_magnitude,
}

minmax_t :: proc(val, min, max: $T) -> (min_result, max_result: T) {
    min_result, max_result = min, max
    if val > max do max_result = val
    if val < min do min_result = val
    return min_result, max_result
}

minmax :: proc {
    rect_minmax,
    minmax_t,
}

slope :: proc {
    vec2_slope,
}