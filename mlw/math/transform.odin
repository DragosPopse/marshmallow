package mmlow_math


import alg "core:math/linalg"



Transform :: struct {
    using pos: Vec3f,
    rot: Vec3f,
    scale: Vec3f,
}

IdentityTransform3D :: Transform {
    pos = {0, 0, 0},
    rot = {0, 0, 0},
    scale = {1, 1, 1},
}

transform_to_mat4f :: proc(t: Transform) -> (m: Mat4f) {
    m = Mat4f(1)
    m *= alg.matrix4_translate(t.pos)
    m *= alg.matrix4_from_euler_angles_xyz_f32(t.rot.x, t.rot.y, t.rot.z)
    m *= alg.matrix4_scale(t.scale)
    return m
}

// Calculate the ModelViewProjection matrix
mvp :: proc(transform: Transform, camera: Camera) -> (m: Mat4f) {
    model := transform_to_mat4f(transform)
    view, projection := camera_to_mat4f(camera)
    return projection * view * model
}