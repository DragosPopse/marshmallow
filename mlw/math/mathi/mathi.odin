package mlw_mathi

import "core:math"
import "core:math/linalg"

Vec2 :: distinct [2]int
Vec3 :: distinct [3]int
Vec4 :: distinct [4]int

Rect :: struct {
    pos: Vec2,
    size: Vec2,
}