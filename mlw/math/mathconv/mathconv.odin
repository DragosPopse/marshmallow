package mlw_mathconv

import "../mathf"
import "../mathi"

vec2_itof :: #force_inline proc(v: mathi.Vec2) -> (result: mathf.Vec2) {
    return {f32(v.x), f32(v.y)}
}

vec3_itof :: #force_inline proc(v: mathi.Vec3) -> (result: mathf.Vec3) {
    return {f32(v.x), f32(v.y), f32(v.z)}
}

rect_itof :: proc(rect: mathi.Rect) -> (result: mathf.Rect) {
    result.pos = #force_inline vec2_itof(rect.pos)
    result.size = #force_inline vec2_itof(rect.size)
    return result
}

col3_btof :: proc(c: mathi.Col3) -> (result: mathf.Col3) {
    result.r = cast(f32)c.r / 255
    result.g = cast(f32)c.g / 255
    result.b = cast(f32)c.b / 255
    return result
}

col4_btof :: proc(c: mathi.Col4) -> (result: mathf.Col4) {
    result.r = cast(f32)c.r / 255
    result.g = cast(f32)c.g / 255
    result.b = cast(f32)c.b / 255
    result.a = cast(f32)c.a / 255
    return result
}

vec2_ftoi :: #force_inline proc(v: mathf.Vec2) -> (result: mathi.Vec2) {
    return {int(v.x), int(v.y)}
}

vec3_ftoi :: #force_inline proc(v: mathf.Vec3) -> (result: mathi.Vec3) {
    return {int(v.x), int(v.y), int(v.z)}
}

rect_ftoi :: proc(rect: mathf.Rect) -> (result: mathi.Rect) {
    result.pos = #force_inline vec2_ftoi(rect.pos)
    result.size = #force_inline vec2_ftoi(rect.size)
    return result
}

col3_ftob :: proc(c: mathf.Col3) -> (result: mathi.Col3) {
    result.r = byte(clamp(c.r, 0, 1) * 255)
    result.g = byte(clamp(c.g, 0, 1) * 255)
    result.b = byte(clamp(c.b, 0, 1) * 255)
    return result
}

col4_ftob :: proc(c: mathf.Col4) -> (result: mathi.Col4) {
    result.r = byte(clamp(c.r, 0, 1) * 255)
    result.g = byte(clamp(c.g, 0, 1) * 255)
    result.b = byte(clamp(c.b, 0, 1) * 255)
    result.a = byte(clamp(c.a, 0, 1) * 255)
    return result
}

itof :: proc {
    vec2_itof,
    vec3_itof,
    rect_itof,
}

ftoi :: proc {
    vec2_ftoi,
    vec3_ftoi,
    rect_ftoi,
}

btof :: proc {
    col3_btof,
    col4_btof,
}

ftob :: proc {
    col3_ftob,
    col4_ftob,
}