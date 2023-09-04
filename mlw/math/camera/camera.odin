package mlw_camera

import "../../math/mathf"
import "../../math/mathi"
import "../../math/mathconv"
import "core:math/linalg"

// Maybe scale of camera is more useful than a rect. Or rect + scale?
Camera2D :: struct {
    using rect: mathf.Rect,
    origin: mathf.Vec2,
    scale: mathf.Vec2,
    rot: mathf.Angle,
}

ortho :: proc(left, right, bottom, top, near, far: f32) -> (result: mathf.Mat4) {
    result = mathf.Mat4(0)
    result[0, 0] = 2.0 / (right - left)
    result[1, 1] = 2.0 / (top - bottom)
    result[2, 2] = 2.0 / (near - far)
    result[3, 3] = 1.0

    result[0, 3] = (left + right) / (left - right)
    result[1, 3] = (bottom + top) / (bottom - top)
    result[2, 3] = (far + near) / (near - far)

    return result
}


@(require_results, optimization_mode = "speed")
camera2d_to_vp_matrix :: proc(c: Camera2D) -> (view_projection: mathf.Mat4) {
    rot := cast(f32)mathf.angle_rad(c.rot)
    c := c
    c.rect.size *= c.scale
    left := 0 - c.size.x * c.origin.x
    right := c.size.x - c.size.x * c.origin.x
    bottom := c.size.y - c.size.y * c.origin.y
    top := 0 - c.size.y * c.origin.y
    projection := linalg.matrix_ortho3d_f32(left, right, bottom, top, -1, 1, true)
    view := mathf.Mat4(1)
    view *= linalg.matrix4_translate_f32({-c.pos.x, -c.pos.y, 0})
    view *= linalg.matrix4_rotate_f32(rot, {0, 0, 1})
    return projection * view
}

camera2d_screen_to_world_position :: proc(c: Camera2D, window_size: mathi.Vec2, pos: mathf.Vec2) -> (result: mathf.Vec2) {
    vp := camera2d_to_vp_matrix(c)
    window_size := mathconv.itof(window_size)
    // note(Dragos): I believe this is only for opengl. Need something else for Direct3D since their NDC is [0, 1]
    x := 2.0 * pos.x / window_size.x - 1
    y := 2.0 * pos.y / window_size.y - 1
    pos := mathf.Vec4{x, -y, -1, 1}
    vp_inv := inverse(vp)
    return (vp_inv * pos).xy
}

screen_to_world_position :: proc {
    camera2d_screen_to_world_position,
}

to_vp_matrix :: proc {
    camera2d_to_vp_matrix,
}