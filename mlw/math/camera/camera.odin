package mlw_camera

import "../../math"
import "core:math/linalg"

// Maybe scale of camera is more useful than a rect. Or rect + scale?
Camera2D :: struct {
    pos: math.Vec2f,
    size: math.Vec2f,
    scale: math.Vec2f,
    rot: math.Angle,
}

@(require_results)
camera2d_to_vp_matrix :: proc(c: Camera2D) -> (view_projection: math.Mat4f) {
    left := -c.size.x * 0.5 * c.scale.x
    right := c.size.x * 0.5 * c.scale.x
    bottom := c.size.y * 0.5 * c.scale.y
    top := -c.size.y * 0.5 * c.scale.y 
    projection := linalg.matrix_ortho3d_f32(left, right, bottom, top, -1, 1, false)
    view := linalg.matrix4_translate_f32({c.pos.x, c.pos.y, 0})
    view *= linalg.matrix4_rotate_f32(cast(f32)math.angle_rad(c.rot), {0, 0, 1})
    return projection * view
}

to_vp_matrix :: proc {
    camera2d_to_vp_matrix,
}