package mmlow_math

import alg "core:math/linalg"

Vec2f :: alg.Vector2f32
Vec3f :: alg.Vector3f32
Vec4f :: alg.Vector4f32
Vec4bt :: distinct [4]byte
Mat3f :: alg.Matrix3f32
Mat4f :: alg.Matrix4f32


Recti :: struct {
    using position: [2]int,
    size: [2]int,
}

Rectf :: struct {
    using position: Vec2f,
    size: Vec2f,
}
