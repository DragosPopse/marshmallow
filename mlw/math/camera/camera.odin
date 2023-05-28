package mlw_camera

import "../../math"
import "core:math/linalg"

// Maybe scale of camera is more useful than a rect. Or rect + scale?
Camera2D :: struct {
    using rect: math.Rectf,
    rotation: math.Angle,
    origin: math.Vec2f,
}

@(require_results)
camera2d_to_vp_matrix :: proc(c: Camera2D) -> (view_projection: math.Mat4f) {
    // Note(Dragos): This is quite slow atm. I'm not sure how to properly handle cameras right now.
    rect := math.rect_align_with_origin(c.rect, c.origin)
    //rect := c.rect
    view := math.Mat4f(1)
    view *= linalg.matrix4_translate_f32({-rect.x, rect.y, 0}) // Note(Dragos): I'm not sure why I need to translate with -x
    view *= linalg.matrix4_rotate_f32(cast(f32)math.angle_rad(c.rotation), {0, 0, 1})
    //view *= linalg.matrix4_scale_f32({c.scale.x, c.scale.y, 1}) // maybedge scaling not needed. Idk man too many operations for a retarded camera
    //view *= linalg.matrix4_translate_f32({c.rect.x, c.rect.y, 0})
    projection := linalg.matrix_ortho3d_f32(0, rect.size.x, 0, -rect.size.y, -1, 1, false)
    return projection * view
}

to_vp_matrix :: proc {
    camera2d_to_vp_matrix,
}