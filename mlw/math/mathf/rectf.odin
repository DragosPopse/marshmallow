package mlw_mathf

// The anchor is relative to the size. an origin of {0.5, 0.5} will mean the center of the rectangle, while {1, 1} would mean bottom right
rect_align_with_anchor :: proc(rect: Rect, anchor: Vec2) -> (result: Rect) {
    rect := rect
    rect.pos -= anchor * rect.size
    return rect
}

// The origin is in local coordinates. An origin of rect.size / 2 would mean the center of the rectangle 
rect_align_with_local_origin :: proc(rect:Rect, origin: Vec2) -> (result: Rect) {
    rect := rect
    rect.pos -= origin
    return rect
}

// The origin is in world coordinates. Useful for setting the origin based on another object
rect_align_with_world_origin :: proc(rect: Rect, origin: Vec2) -> (result: Rect) {
    origin := rect.pos - origin // Needs testing. 
    return rect_align_with_local_origin(rect, origin)
}

rect_minmax :: proc(rect: Rect) -> (min, max: Vec2) {
    return rect.pos, rect.pos + rect.size
}

// Set new width, keeping the ratio
rect_ratio_resize_width :: proc(rect: Rect, width: f32) -> (result: Rect) {
    ratio := rect.size.y / rect.size.x
    result.pos = rect.pos
    result.size.x = width
    result.size.y = ratio * width
    return result
}
