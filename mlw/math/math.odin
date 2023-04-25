package mmlow_math

import "core:math/linalg"

minmax :: proc(val, min, max: $T) -> (min_result, max_result: T) {
    min_result, max_result = min, max
    if val > max do max_result = val
    if val < min do min_result = val
    return min_result, max_result
}


aabb_rectf :: proc(a, b: Rectf) -> bool {
    if a.x < b.x + b.size.x && 
       a.x + a.size.x > b.x && 
       a.y < b.y + b.size.y &&
       a.y + a.size.y > b.y {
        return true
    }
    return false
}

aabb_recti :: proc(a, b: Recti) -> bool {
    if a.x < b.x + b.size.x && 
       a.x + a.size.x > b.x && 
       a.y < b.y + b.size.y &&
       a.y + a.size.y > b.y {
        return true
    }
    return false
}

aabb :: proc {
    aabb_rectf, 
    aabb_recti,
}

normalize :: linalg.normalize
length :: linalg.length