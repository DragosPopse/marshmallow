package mlw_ps

import "../../core"
import "../../math"
import "../../imdraw"

import "core:slice"
import "core:math/linalg"
import "core:math/rand"
import "core:fmt"
import "core:mem"
import "core:runtime"

// Note(Dragos): We should somehow integrate this in the rendering pipeline to save some bytes.
// Note(Dragos): Should we have affectors? Maybe


Particle :: struct {
    rect: math.Rectf,
    origin: math.Vec2f,
    color: math.Color4f,
    tex_index: int,
    rotation: math.Angle,
    velocity: math.Vec2f,
    remaining_life: f32,
}

Emitter_Connection :: distinct u64
Affector_Connection :: distinct u64


Stream_Emitter :: struct {
    emitter: core.Value_Or_Ref(Emitter),
    remaining_lifetime: Maybe(f32),
    spawn_counter: f32, // Accumulates each frame
}

Particle_System :: struct {
    position: math.Vec2f,
    texture: Maybe(imdraw.Texture),
    texture_rects: []math.Recti,
    
    _particles: [dynamic]Particle,
    _emitters: map[Emitter_Connection]Stream_Emitter, // These will be stream emitters
    _em_connection_index: Emitter_Connection,
}

Emitter :: struct {
    part_position: math.Distribution(math.Vec2f),
    part_size: math.Distribution(f32),
    part_origin: math.Vec2f,
    emission_rate: int,
    part_velocity: math.Distribution(math.Vec2f),
    part_lifetime: math.Distribution(f32),
    part_tex_index: math.Distribution(int),
    part_color: math.Color4f,
}

particle_update :: proc(particle: ^Particle, dt: f32, r: ^rand.Rand = nil) {
    particle.rect.pos += particle.velocity * dt
}

emit_create_particle :: proc(em: Emitter, r: ^rand.Rand = nil) -> (particle: Particle) {
    particle.rect.pos = math.eval(em.part_position, r)
    particle.rect.size = math.eval(em.part_size, r)
    particle.origin = em.part_origin
    particle.color = em.part_color // Todo(Dragos): this should also be some sort of distribution. Maybe a gradient
    particle.tex_index = math.eval(em.part_tex_index, r)
    particle.rotation = math.Rad(0) // Todo(Dragos): distribution this
    particle.velocity = math.eval(em.part_velocity, r)
    particle.remaining_life = math.eval(em.part_lifetime, r)
    return particle
}

emit_stream :: proc(ps: ^Particle_System, em: core.Value_Or_Ref(Emitter), lifetime: Maybe(math.Distribution(f32)) = nil, r: ^rand.Rand = nil) -> (conn: Emitter_Connection) {
    psem: Stream_Emitter
    psem.remaining_lifetime = math.eval(lifetime.(math.Distribution(f32)), r) if lifetime != nil else nil
    psem.emitter = em
    map_insert(&ps._emitters, ps._em_connection_index, psem)
    conn = ps._em_connection_index
    ps._em_connection_index += 1
    return conn
}

update :: proc(ps: ^Particle_System, dt: f32, r: ^rand.Rand = nil) {
    { // Update emitters
        for em_key, em in &ps._emitters {
            lifetime, has_lifetime := &em.remaining_lifetime.(f32)
            if has_lifetime {
                lifetime^ -= dt
                if lifetime^ <= 0 {
                    delete_key(&ps._emitters, em_key)
                    continue
                }
            }
            emitter := core.value_or_ref_ptr(&em.emitter)
            em.spawn_counter += cast(f32)emitter.emission_rate * dt

            for em.spawn_counter >= 1 {
                em.spawn_counter -= 1
                particle := emit_create_particle(emitter^, r)
                append(&ps._particles, particle)
            }
        }
    }

    { // Update alive particles
        for i := 0; i < len(ps._particles); /**/ {
            particle := &ps._particles[i]
            particle.remaining_life -= dt
            if particle.remaining_life <= 0 {
                unordered_remove(&ps._particles, i)
                continue
            }
            i += 1
            particle_update(particle, dt, r)
        }
    }
}

draw :: proc(ps: Particle_System) {
    if ps.texture != nil do for particle in ps._particles {
        imdraw.sprite(ps.texture.(imdraw.Texture), particle.rect, particle.origin, ps.texture_rects[particle.tex_index], particle.rotation, particle.color)
    } else do for particle in ps._particles {
        imdraw.quad(particle.rect, particle.origin, particle.rotation, particle.color)
    }     
}

