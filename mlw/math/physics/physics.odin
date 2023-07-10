package mlw_physics

import "../../math"
import "../../math/grids"
import cmath "core:math"
import linalg "core:math/linalg"

Collider_Type :: enum {
    Solid,
    Trigger,
}

// 
Collider :: struct {
    type: Collider_Type,
    offset: math.Vec2f,
}

Box_Collider :: struct {
    using base: Collider,
    size: math.Vec2f,
}

Circle_Collider :: struct {
    using base: Collider,
    radius: f32,
}

Capsule_Collider :: struct {
    using base: Collider,
    size: math.Vec2f,
    radius: f32,
}

Any_Collider :: union {
    Box_Collider,
    Circle_Collider,
    Capsule_Collider,
}

Body_Type :: enum {
    Static,
    Dynamic,
    Kinematic,
}

Body :: struct {
    type: Body_Type,
    world: ^World,
    pos: math.Vec2f,
    mass: f32,
    drag: f32,
    gravity_scale: f32,
    velocity: math.Vec2f,
    collider: Any_Collider,
    user_index: int,
    user_data: rawptr,
}

Step_Proc :: #type proc(world: ^World)

World :: struct {
    gravity: math.Vec2f,
    timestep: f32,
    accum_dt: f32,
    step_proc: Step_Proc,
    dynamic_bodies: [dynamic]^Body,
    static_bodies: [dynamic]^Body,
    kinematic_bodies: [dynamic]^Body,
}

Collision_Pair :: struct {
    body1, body2: ^Body,
}

Collision_Info :: struct {
    penetration: math.Vec2f,
    normal: math.Vec2f,
    impulse: f32, // This is kinda wrong, but we'll make it better as we go along
    contact: math.Vec2f,
}

solve_collision_dynamic_static :: proc(db: ^Body, sb: ^Body) -> Maybe(Collision_Info) {
    assert(db.type == .Dynamic && sb.type == .Static, "Invalid parameters. Expected dynamic and static bodies.")
    db_box, db_is_box := db.collider.(Box_Collider)
    sb_box, sb_is_box := sb.collider.(Box_Collider)
    assert(db_is_box && sb_is_box, "Only box colliders are currently supported")
    sb_rect: math.Rectf
    db_rect: math.Rectf
    sb_rect.pos = sb.pos + sb_box.offset
    sb_rect.size = sb_box.size
    db_rect.pos = db.pos + db_box.offset
    db_rect.size = db_box.size
    if penetration, normal := math.solve_collision(sb_rect, db_rect); penetration != nil {
        cinfo: Collision_Info
        cinfo.penetration = penetration.?
        cinfo.normal = normal
        cinfo.impulse = -linalg.dot(sb.velocity, normal) / 2
    }
    return nil
}

step :: proc(using world: ^World, dt: f32) {
    accum_dt += dt
    for accum_dt > timestep {
        accum_dt -= timestep
        if step_proc != nil do step_proc(world)
        // Todo(Dragos): Optimize this with a broad-phase data structure
        for db in dynamic_bodies { 
            // gravity 
            body_add_force(db, gravity, .Force)

            // air drag
            if linalg.length2(db.velocity) > 0 {
                dir := linalg.normalize(db.velocity)
                body_add_force(db, -dir * db.drag, .Force)
            }

            db.pos.x += db.velocity.x * timestep
            for sb in static_bodies {
                if cinfo := solve_collision_dynamic_static(db, sb); cinfo != nil {
                    cinfo := cinfo.?
                    db.pos -= cinfo.penetration
                    db.velocity.x += cinfo.impulse * cinfo.normal.x
                }
            }

            db.pos.y += db.velocity.y * timestep
            for sb in static_bodies {
                if cinfo := solve_collision_dynamic_static(db, sb); cinfo != nil {
                    cinfo := cinfo.?
                    db.pos -= cinfo.penetration
                    db.velocity.y += cinfo.impulse * cinfo.normal.y
                }
            }
        }
    }
}

Force_Type :: enum {
    Force,
    Impulse,
}

body_add_force :: proc(body: ^Body, force: math.Vec2f, type: Force_Type = .Force) {
    // Is this correct? Or should I multiply by another time step?
    // Note: in unity, i think you are supposed to say smth like force * dt, because the force is defined by len / dt * dt, so it would cancel?
    switch type {
    case .Force: body.velocity += force * body.world.timestep
    case .Impulse: body.velocity += force
    }
}

body_make :: proc(world: ^World, type: Body_Type, allocator := context.allocator) -> (body: ^Body) {
    body = new(Body, allocator)
    body.type = type
    body.world = world
 
    switch body.type {
    case .Static: append(&world.static_bodies, body)
    case .Dynamic:
        body.mass = 1
        body.gravity_scale = 1
        append(&world.dynamic_bodies, body)
    case .Kinematic: append(&world.kinematic_bodies, body)
    }
    return body
}