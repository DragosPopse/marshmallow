package mlw_random

import "../../math/mathf"
import "../../math/mathi"
import "core:fmt"
import "core:intrinsics"
import cmath "core:math"

Uniform_Distribution :: struct($T: typeid) {
    min: T,
    max: T,
}

Circle_Distribution :: struct($T: typeid) {
    pos: T,
    radius: f32,
}

// Haha, annulus
Annulus_Distribution :: struct($T: typeid) {
    pos: T,
    inner: f32,
    outer: f32,
}

Distribution :: union($T: typeid) {
    T, 
    Uniform_Distribution(T),
    Circle_Distribution(T),
    Annulus_Distribution(T),
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

uniform_rect :: proc "contextless" (rect: mathf.Rect) -> (result: Uniform_Distribution(mathf.Vec2)) {
    result.min = rect.pos
    result.max = rect.pos + rect.size
    return result
}

uniform_vec2f :: proc "contextless" (min, max: mathf.Vec2) -> (result: Uniform_Distribution(mathf.Vec2)) {
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

circle_dist :: proc "contextless" (pos: mathf.Vec2, radius: f32) -> (result: Circle_Distribution(mathf.Vec2)) {
    result.pos = pos
    result.radius = radius
    return result
}

annulus_dist :: proc "contextless" (pos: mathf.Vec2, inner, outer: f32) -> (result: Annulus_Distribution(mathf.Vec2)) {
    result.pos = pos
    result.inner = inner
    result.outer = outer
    return result
}

eval_dist :: proc(d: Distribution($T), r: ^Generator) -> (result: T) {
    switch var in d {
        case T: return var
        case Uniform_Distribution(T): return #force_inline eval_uniform_dist(var, r)
        case Circle_Distribution(T): return #force_inline eval_circle_dist(var, r)
        case Annulus_Distribution(T): return #force_inline eval_annulus_dist(var, r)
    }
    return //unreachable
}

eval :: proc {
    eval_dist,
}

eval_uniform_dist :: proc(d: Uniform_Distribution($T), r: ^Generator) -> (result: T) {
    when intrinsics.type_is_array(T) {
        rect: mathf.Rect
        rect.x = cast(f32)d.min.x
        rect.y = cast(f32)d.min.y
        rect.size.x = f32(d.max.x - d.min.x) 
        rect.size.y = f32(d.max.y - d.min.y)
        result.x = cast(type_of(result.x))(rect.x + rect.size.x * float(r))
        result.y = cast(type_of(result.y))(rect.y + rect.size.y * float(r))
        return result
    } else when intrinsics.type_is_float(T) || intrinsics.type_is_integer(T) {
        return cast(T)(f64(d.max - d.min) * double(r)) + d.min 
    } else {
        fmt.panicf("The type %v is not implemented in eval_uniform_distribution.", T)
    }
}

eval_circle_dist :: proc(d: Circle_Distribution($T), r: ^Generator) -> (result: T) {
    when intrinsics.type_is_array(T) {
        // Rejection sampling as they call it, would this be ok? It seems goofy
        for {
            result.x = float_range(-1, 1, r) 
            result.y = float_range(-1, 1, r)
            if result.x * result.x + result.y * result.y <= 1 {
                return d.pos + result * d.radius
            }
        }
    } 

    return result
}

eval_annulus_dist :: proc(d: Annulus_Distribution($T), r: ^Generator) -> (result: T) {
    when intrinsics.type_is_array(T) {
        theta := float(r) * 2 * mathf.PI
        distance := cmath.sqrt_f32(float(r) * (d.inner * d.inner - d.outer * d.outer) + d.outer * d.outer)
        result.x = distance * mathf.cos(theta)
        result.y = distance * mathf.sin(theta)
        result += d.pos
    }

    return result
}
