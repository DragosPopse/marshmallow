package mlw_mathf

import "core:math"

sin :: math.sin
cos :: math.cos
tan :: math.tan
atan :: math.atan
atan2 :: math.atan2
asin :: math.asin
acos :: math.acos

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

direction_to_angle :: proc(direction: Vec2) -> (angle: Angle) {
    rads := cast(f32)math.atan2(direction.y, direction.x)
    return cast(Rad)rads
}

angle_to_direction :: proc(angle: Angle) -> (direction: Vec2) {
    rads := cast(f32)angle_rad(angle)
    direction.x = math.cos(rads)
    direction.y = math.sin(rads)
    return direction
}