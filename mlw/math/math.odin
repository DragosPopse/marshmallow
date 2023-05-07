package mmlow_math

import "core:math/linalg"
import cmath "core:math"
import "core:intrinsics"

floor :: cmath.floor
normalize :: linalg.normalize
length :: linalg.length
PI :: cmath.PI
vec_length :: linalg.vector_length

// Note(Dragos): These should only accept Deg/Rad
sin :: cmath.sin
cos :: cmath.cos
tan :: cmath.tan
atan :: cmath.atan
atan2 :: cmath.atan2

DEG_PER_RAD :: cmath.DEG_PER_RAD
RAD_PER_DEG :: cmath.RAD_PER_DEG

floor_to_int :: proc(v: $T) -> int where intrinsics.type_is_float(T) {
    return cast(int)floor(v)
}

// Note(Dragos): remove linalg dependency as much as possible
//              we don't need all of it. It's too large, too 'templated'

Vec2f :: linalg.Vector2f32
Vec2i :: distinct [2]int

Vec3f :: linalg.Vector3f32
Vec3i :: distinct [3]int

Vec4f :: linalg.Vector4f32
Vec4i :: distinct [4]int
Vec4bt :: distinct [4]byte

Mat3f :: linalg.Matrix3f32
Mat4f :: linalg.Matrix4f32

// Specialized types for usage in overloading functions and making nicer apis
Scale2f :: distinct Vec2f
Scale3f :: distinct Vec3f

Pos2f :: distinct Vec2f
Pos3f :: distinct Vec2f

Size2f :: distinct Vec2f
Size3f :: distinct Vec3f

Line2f :: struct {
    begin: Vec2f,
    end: Vec2f,
}

Recti :: struct {
    using pos: Vec2i, 
    size: Vec2i,
}

Rectf :: struct {
    using pos: Vec2f,
    size: Vec2f,
}

// Conceptual types for handling degrees and radians operations. The resulting code will be a bit more verbose, but the result will be clearer
Rad :: distinct f32
Deg :: distinct f32
Angle :: union {
    Rad,
    Deg,
}

deg_to_rad :: proc(degrees: Deg) -> Rad {
    return Rad(degrees * RAD_PER_DEG)
}

rad_to_deg :: proc(radians: Rad) -> Deg {
    return Deg(radians * DEG_PER_RAD)
}

angle_deg :: proc(angle: Angle) -> (rad: Deg) {
    switch var in angle {
        case Deg: return var
        case Rad: return #force_inline rad_to_deg(var)
    }
    return
}

angle_rad :: proc(angle: Angle) -> (rad: Rad) {
    switch var in angle {
        case Deg: return #force_inline deg_to_rad(var)
        case Rad: return var
    }
    return
}

vec2i_to_vec2f :: proc(val: Vec2i) -> (res: Vec2f) {
    res.x = cast(f32)val.x
    res.y = cast(f32)val.y
    return res
}

to_vec2f :: proc {
    vec2i_to_vec2f,
}

vec2f_to_vec2i :: proc(val: Vec2f) -> (res: Vec2i) {
    res.x = cast(int)val.x
    res.y = cast(int)val.y
    return res
}

to_vec2i :: proc {
    vec2f_to_vec2i,
}

vec3i_to_vec3f :: proc(val: Vec3i) -> (res: Vec3f) {
    res.x = cast(f32)val.x
    res.y = cast(f32)val.y
    res.z = cast(f32)val.z
    return res
}

vec3f_to_vec3i :: proc(val: Vec3f) -> (res: Vec3i) {
    res.x = cast(int)val.x
    res.y = cast(int)val.y
    res.z = cast(int)res.z
    return res
}

recti_to_rectf :: proc(val: Recti) -> (res: Rectf) {
    res.pos = #force_inline to_vec2f(val.pos)
    res.size = #force_inline to_vec2f(val.size)
    return res
}

to_rectf :: proc {
    recti_to_rectf,
}

rectf_to_recti :: proc(val: Rectf) -> (res: Recti) {
    res.pos = #force_inline to_vec2i(val.pos)
    res.size = #force_inline to_vec2i(val.size)
    return res
}

to_recti :: proc {
    rectf_to_recti,
}


minmax_t :: proc(val, min, max: $T) -> (min_result, max_result: T) {
    min_result, max_result = min, max
    if val > max do max_result = val
    if val < min do min_result = val
    return min_result, max_result
}

minmax_rectf :: proc(r: Rectf) -> (topleft: Vec2f, bottomright: Vec2f) {
    return r.pos, r.pos + r.size
}

minmax_recti :: proc(r: Recti) -> (topleft: Vec2i, bottomright: Vec2i) {
    return r.pos, r.pos + r.size
}

minmax :: proc {
    minmax_t,
    minmax_rectf,
    minmax_recti,
}

rectf_align_with_origin :: proc(r: Rectf, origin: Vec2f) -> (res: Rectf) {
    res = r
    res.pos -= origin * r.size
    return res
}

recti_align_with_origin :: proc(r: Recti, origin: Vec2f) -> (res: Recti) {
    res = r
    res.pos -= to_vec2i(origin * to_vec2f(r.size))
    return res
}

rect_align_with_origin :: proc {
    rectf_align_with_origin,
    recti_align_with_origin,
}


// Todo(Dragos): Rename this as `rect_origin_point`. The center is just a center
rectf_center :: proc(r: Rectf, origin: Vec2f) -> (res: Vec2f) {
    return r.pos + r.size * origin
}

rect_center :: proc {
    rectf_center,
}

rectf_origin_from_world_point :: proc(r: Rectf, point: Vec2f) -> (origin: Vec2f) {
    return (point - r.pos) / r.size
}

rectf_origin_from_relative_point :: proc(r: Rectf, point: Vec2f) -> (origin: Vec2f) {
    origin = point / r.size 
    return origin
}

rect_origin_from_world_point :: proc {
    rectf_origin_from_world_point, 
}

rect_origin_from_relative_point :: proc {
    rectf_origin_from_relative_point, 
}

check_collision_rectf_rectf :: proc(a, b: Rectf) -> bool {
    diff := minkowski_diff(a, b)
    diff_min, diff_max := minmax(diff)
    if diff_min.x <= 0 && diff_max.x >= 0 && diff_min.y <= 0 && diff_max.y >= 0 {
        return true
    }
    return false
}

solve_collision_rectf_rectf :: proc(a, b: Rectf) -> (penetration_vector: Maybe(Vec2f)) {
    diff := minkowski_diff(a, b)
    diff_min, diff_max := minmax(diff)
    if diff_min.x <= 0 && diff_max.x >= 0 && diff_min.y <= 0 && diff_max.y >= 0 {
        return rectf_closest_point_on_bounds_to_point(diff, {0, 0})
    }
    return nil
}

solve_collision :: proc {
    solve_collision_rectf_rectf,
}

check_collision :: proc {
    check_collision_rectf_rectf,
}

minkowski_diff_rectf_rectf :: proc(a: Rectf, b: Rectf) -> (result: Rectf) {
    result.pos = a.pos - b.pos - b.size
    result.size = a.size + b.size
    return result
}

minkowski_diff :: proc {
    minkowski_diff_rectf_rectf,
}

rectf_closest_point_on_bounds_to_point :: proc(r: Rectf, point: Vec2f) -> (bounds_point: Vec2f) {
    topleft, bottomright := minmax(r)
    min_dist := abs(point.x - topleft.x)
    bounds_point = {topleft.x, point.y}

    if m := abs(bottomright.x - point.x); m < min_dist {
        min_dist = m
        bounds_point = {bottomright.x, point.y}
    }
    if m := abs(bottomright.y - point.y); m < min_dist {
        min_dist = m
        bounds_point = {point.x, bottomright.y}
    }
    if m := abs(topleft.y - point.y); m < min_dist {
        min_dist = m
        bounds_point = {point.x, topleft.y}
    }

    return bounds_point
}

rect_closest_point_on_bounds_to_point :: proc {
    rectf_closest_point_on_bounds_to_point,
}

vec2f_slope :: proc(a, b: Vec2f) -> f32 {
    return (b.y - a.y) / (b.x - a.x)
}

slope :: proc {
    vec2f_slope,
}