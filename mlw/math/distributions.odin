package mlw_math

import "core:math/linalg"
import "core:fmt"
import cmath "core:math"
import "core:math/rand"
import "core:intrinsics"

Uniform_Distribution :: struct($T: typeid) {
    min: T,
    max: T,
}

Circle_Distribution :: struct($T: typeid) {
    pos: T,
    radius: f32,
}

Distribution :: union($T: typeid) {
    T, 
    Uniform_Distribution(T),
    Circle_Distribution(T),
}

uniform_int :: proc "contextless" (min, max: int) -> (result: Uniform_Distribution(int)) {
    result.min = min
    result.max = max
    return result
}

uniform_float :: proc "contextless" (min, max: f32) -> (result: Uniform_Distribution(f32)) {
    result.min = min
    result.max = max
    return result
}

uniform_rect :: proc "contextless" (rect: Rectf) -> (result: Uniform_Distribution(Vec2f)) {
    result.min = rect.pos
    result.max = rect.pos + rect.size
    return result
}

uniform_vec2f :: proc "contextless" (min, max: Vec2f) -> (result: Uniform_Distribution(Vec2f)) {
    result.min = min
    result.max = max
    return result
}

uniform_dist :: proc {
    uniform_int,
    uniform_float,
    uniform_rect,
    uniform_vec2f,
}

circle_dist :: proc "contextless" (pos: Vec2f, radius: f32) -> (result: Circle_Distribution(Vec2f)) {
    result.pos = pos
    result.radius = radius
    return result
} 

eval_dist :: proc(d: Distribution($T), r: ^rand.Rand = nil) -> (result: T) {
    switch var in d {
        case T: return var
        case Uniform_Distribution(T): return #force_inline eval_uniform_dist(var, r)
        case Circle_Distribution(T): return #force_inline eval_circle_dist(var, r)
    }
    return //unreachable
}

eval :: proc {
    eval_dist,
}

eval_uniform_dist :: proc(d: Uniform_Distribution($T), r: ^rand.Rand = nil) -> (result: T) {
    when intrinsics.type_is_array(T) {
        rect: Rectf
        rect.x = cast(f32)d.min.x
        rect.y = cast(f32)d.min.y
        rect.size.x = f32(d.max.x - d.min.x) 
        rect.size.y = f32(d.max.y - d.min.y)
        result.x = cast(type_of(result.x))(rect.x + rect.size.x * rand.float32(r))
        result.y = cast(type_of(result.y))(rect.y + rect.size.y * rand.float32(r))
        return result
    } else when intrinsics.type_is_float(T) || intrinsics.type_is_integer(T) {r
        return cast(T)(f64(d.max - d.min) * rand.float64(r)) + d.max 
    } else {
        fmt.panicf("The type %v is not implemented in eval_uniform_distribution.", T)
    }
}

eval_circle_dist :: proc(d: Circle_Distribution($T), r: ^rand.Rand = nil) -> (result: T) {
    when intrinsics.type_is_array(T) {
        // Rejection sampling as they call it, would this be ok? It seems goofy
        for {
            result.x = rand.float32_range(-1, 1, r) 
            result.y = rand.float32_range(-1, 1, r)
            if result.x * result.x + result.y * result.y <= 1 {
                return d.pos + result * d.radius
            }
        }
    } 

    return result
}

