package mlw_camera

import "../../math"
import "core:math/linalg"

// Maybe scale of camera is more useful than a rect. Or rect + scale?
Camera2D :: struct {
    rect: math.Rectf,
    rotation: math.Angle,
    scale: math.Vec2f,
    origin: math.Vec2f,
    projection: Mat4f,
}

@(require_results)
camera2d_to_vp_matrix :: proc(c: Camera2D) -> (view_projection: Mat4f) {
    // Note(Dragos): This is quite slow atm. I'm not sure how to properly handle cameras right now.
    rect := math.rect_align_with_origin(c.origin)
    view := linalg.matrix4_translate_f32({rect.x, rect.y, 0})  
    view *= linalg.matrix4_rotate_f32(math.angle_rad(c.rotation), {0, 0, 1})
    view *= linalg.matrix4_scale_f32({c.scale.x, c.scale.y, 1})
    projection := linalg.matrix_ortho3d_f32(-rect.size.x, rect.size.x, rect.size.y, -rect.size.y, -1, 1, false) // maybe this too..
    return projection * view
}

to_vp_matrix :: proc {
    camera2d_to_vp_matrix,
}