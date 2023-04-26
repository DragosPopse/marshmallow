package mmlow_math

import "core:math/linalg"

normalize :: linalg.normalize
length :: linalg.length

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

Recti :: struct {
    using pos: Vec2i, 
    size: Vec2i,
}

Rectf :: struct {
    using pos: Vec2f,
    size: Vec2f,
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


minmax :: proc(val, min, max: $T) -> (min_result, max_result: T) {
    min_result, max_result = min, max
    if val > max do max_result = val
    if val < min do min_result = val
    return min_result, max_result
}


rectf_rectf_collision :: proc(a, b: Rectf) -> bool {
    if a.x < b.x + b.size.x && 
       a.x + a.size.x > b.x && 
       a.y < b.y + b.size.y &&
       a.y + a.size.y > b.y {
        return true
    }
    return false
}

rectf_rectf_collision_origin :: proc(a, b: Rectf, origin: Vec2f) -> bool {
    return rectf_rectf_collision_origin2(a, b, origin, origin)
}

rectf_rectf_collision_origin2 :: proc(a, b: Rectf, a_origin, b_origin: Vec2f) -> bool {
    if a.x - a.size.x * a_origin.x < b.x + b.size.x - b.size.x * b_origin.x && 
        a.x + a.size.x - a.size.x * a_origin.x > b.x - b.size.x * b_origin.x && 
        a.y - a.size.y * a_origin.y < b.y + b.size.y - b.size.y * b_origin.y &&
        a.y + a.size.y - a.size.y * a_origin.y > b.y - b.size.y * b_origin.y {
        return true
    }
    return false
}


rect_rect_collision :: proc {
    rectf_rectf_collision,
    rectf_rectf_collision_origin,
    rectf_rectf_collision_origin2,
}

rectf_vec2f_collision :: proc(a: Rectf, v: Vec2f) -> bool {
    if a.x < v.x && a.x + a.size.x > v.x && a.y < v.y && a.y + a.size.y > v.y {
        return true
    }
    return false
}

recti_vec2i_collision :: proc(a: Recti, v: Vec2i) -> bool {
    if a.x < v.x && a.x + a.size.x > v.x && a.y < v.y && a.y + a.size.y > v.y {
        return true
    }
    return false
}

rect_vec2i_collision :: proc {
    rectf_vec2f_collision,
    recti_vec2i_collision,
}

rectf_clamp_outside_rectf :: proc(val: Rectf, r: Rectf) -> (result: Rectf) {
    return result
}

recti_clamp_outside_recti :: proc(val: Recti, r: Recti) -> (result: Recti) {
    return result    
}

rectf_clamp_inside_rectf :: proc(val: Rectf, r: Rectf, val_origin := Vec2f{0, 0}, r_origin := Vec2f{0, 0}) -> (result: Rectf) {
    result.size = val.size
    result.x = clamp(val.x, r.x - r_origin.x * r.size.x + val_origin.x * val.size.x, r.x + r.size.x - r_origin.x * r.size.x - val_origin.x * val.size.x)
    result.y = clamp(val.y, r.y - r_origin.y * r.size.y + val_origin.y * val.size.y, r.y + r.size.y - r_origin.y * r.size.y - val_origin.y * val.size.y)
    return result
}

vec2f_clamp_inside_rectf :: proc(val: Vec2f, r: Rectf, r_origin := Vec2f{0, 0}) -> (result: Vec2f) {
    result.x = clamp(val.x, r.x, r.x + r.size.x)
    result.y = clamp(val.y, r.pos.y, r.pos.y + r.size.y)
    return result
}

clamp_inside_rectf :: proc {
    rectf_clamp_inside_rectf,
    vec2f_clamp_inside_rectf,
}

clamp_inside_rect :: proc {
    rectf_clamp_inside_rectf,
    vec2f_clamp_inside_rectf,
}







