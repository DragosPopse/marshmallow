package mlw_math


Camera :: struct {
    transform: Transform,
    projection: Mat4f,
}

@(require_results)
camera_to_vp_matrices :: proc(c: Camera) -> (view: Mat4f, projection: Mat4f) {
    return transform_to_mat4f(c.transform), c.projection
}

@(require_results)
camera_to_vp_matrix :: proc(c: Camera) -> (view_projection: Mat4f) {
    view := transform_to_mat4f(c.transform)
    projection := c.projection
    return projection * view
}