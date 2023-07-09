package mlw_physics

import "../../math"
import "../../math/grids"

AABB_Collider :: struct {
    using rect: math.Rectf,
}

Collider :: union {
    AABB_Collider,
}

Trace_Info :: struct {
    normal: math.Vec2f,
}


