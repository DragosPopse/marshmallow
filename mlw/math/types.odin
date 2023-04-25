package mmlow_math

import alg "core:math/linalg"

Vec2f :: alg.Vector2f32
Vec3f :: alg.Vector3f32
Vec4f :: alg.Vector4f32
Vec4bt :: distinct [4]byte
Mat3f :: alg.Matrix3f32
Mat4f :: alg.Matrix4f32

// Specialized types for usage in overloading functions and making nicer apis
Scale2f :: distinct Vec2f
Scale3f :: distinct Vec3f

Pos2f :: distinct Vec2f
Pos3f :: distinct Vec2f

Size2f :: distinct Vec2f
Size3f :: distinct Vec3f


Recti :: struct {
    using pos: [2]int,
    size: [2]int,
}

Rectf :: struct {
    using pos: Vec2f,
    size: Vec2f,
}
