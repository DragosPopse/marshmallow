package mmlow_math


Camera :: struct {
    transform: Transform,
    projection: Mat4f,
}

@(require_results)
camera_to_mat4f :: proc(c: Camera) -> (transform: Mat4f, projection: Mat4f) {
    transform = transform_to_mat4f(c.transform)
    projection = c.projection
    return
}