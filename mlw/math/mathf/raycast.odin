package mlw_mathf

Raycast_Info :: struct {
    entry: Vec2,
    exit: Maybe(Vec2),
    penetration: Vec2,
    normal: Vec2,
}

raycast_rect :: proc(rect: Rect, ray_orig: Vec2, ray_dir: Vec2, dist := INFINITY) -> Maybe(Raycast_Info) {
    info: Raycast_Info
    rmin, rmax := minmax(rect)
    tmin := f32(0)
    tmax := dist
    t1 := (rmin.x - ray_orig.x) / ray_dir.x
    t2 := (rmax.x - ray_orig.x) / ray_dir.x
    t3 := (rmin.y - ray_orig.y) / ray_dir.y
    t4 := (rmax.y - ray_orig.y) / ray_dir.y

    tmin = max(min(t1, t2), min(t3, t4), tmin)
    tmax = min(max(t1, t2), max(t3, t4), tmax)


    if tmax < 0 { // ray goes the other way
        return nil
    }

    if tmin > tmax { // they dont intersect
        return nil
    }

    if tmin < 0 { // ray interesects, the origin is inside the rect
        info.entry = ray_orig + tmax * ray_dir
        return info
    }
    info.entry = ray_orig + tmin * ray_dir
    info.exit = ray_orig + tmax * ray_dir if tmax < dist else nil
    
    return info
}