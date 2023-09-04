package mlw_mathf

// The origin is relative to the size. an origin of {0.5, 0.5} will mean the center of the rectangle, while {1, 1} would mean bottom right
rect_align_with_relative_origin :: proc(rect: Rect, origin: Vec2) -> (result: Rect) {
    rect := rect
    rect.pos -= origin * rect.size
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

rect_minmax_n :: proc(rect: ..Rect) -> (min, max: Vec2) {
    unimplemented()
}

// Set new width, keeping the ratio
rect_ratio_resize_width :: proc(rect: Rect, width: f32) -> (result: Rect) {
    ratio := rect.size.y / rect.size.x
    result.pos = rect.pos
    result.size.x = width
    result.size.y = ratio * width
    return result
}

minkowski_diff_rect_rect :: proc(a, b: Rect) -> (result: Rect) {
    result.pos = a.pos - b.pos - b.size
    result.size = a.size + b.size
    return result
}

rect_closest_point_on_bounds_to_point :: proc(r: Rect, point: Vec2) -> (bounds_point: Vec2) {
    topleft, bottomright := minmax(r)
    min_dist := abs(point.x - topleft.x)
    bounds_point = {topleft.x, point.y}

    if m := abs(bottomright.x - point.x); m < min_dist {
        min_dist = m
        bounds_point = {bottomright.x, point.y}
    }
    if m := abs(bottomright.y - point.y); m < min_dist {
        min_dist = m
        bounds_point = {point.x, bottomright.y}
    }
    if m := abs(topleft.y - point.y); m < min_dist {
        min_dist = m
        bounds_point = {point.x, topleft.y}
    }

    return bounds_point
}