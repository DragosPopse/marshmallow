package mlw_physics

import "../../math"
import "../../math/grids"


Box_Collider :: struct {
    offset: math.Vec2f,
    size: math.Vec2f,
}

Circle_Collider :: struct {
    offset: math.Vec2f,
    radius: f32,
}

Capsule_Collider :: struct {
    offset: math.Vec2f,
    size: math.Vec2f,
    radius: f32,
}

Collider :: union {
    Box_Collider,
    Circle_Collider,
    Capsule_Collider,
}

Trace_Info :: struct {
    normal: math.Vec2f,
}

Body :: struct {
    pos: math.Vec2f,
    collider: Collider,
    user_index: int,
    user_data: rawptr,
}

