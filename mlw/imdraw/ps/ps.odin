package mlw_ps

import "../../core"
import "../../math/mathf"
import "../../math/mathi"
import "../../imdraw"
import "../../math/random"

import "core:slice"
import "core:math/linalg"
import "core:math/rand"
import "core:fmt"
import "core:mem"
import "core:runtime"

// Note(Dragos): We should somehow integrate this in the rendering pipeline to save some bytes.
// Note(Dragos): Should we have affectors? Maybe


Particle :: struct {
    rect: mathf.Rect,
    origin: mathf.Vec2,
    color: mathf.Col4,
    tex_index: int,
    rotation: mathf.Angle,
    velocity: mathf.Vec2,
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
    position: mathf.Vec2,
    texture: Maybe(imdraw.Texture),
    texture_rects: []mathi.Rect,
    
    _particles: [dynamic]Particle,
    _emitters: map[Emitter_Connection]Stream_Emitter, // These will be stream emitters
    _em_connection_index: Emitter_Connection,
}

// Note(Dragos): IDEA - just allow the user to slice the active particles, so they can implement affectors themselves
Emitter :: struct {
    part_position: random.Distribution(mathf.Vec2),
    part_size: random.Distribution(f32),
    part_origin: mathf.Vec2,
    emission_rate: int,
    part_velocity: random.Distribution(mathf.Vec2),
    part_lifetime: random.Distribution(f32),
    part_tex_index: random.Distribution(int),
    part_color: mathf.Col4,
}

particle_update :: proc(particle: ^Particle, dt: f32, r: ^random.Generator) {
    particle.rect.pos += particle.velocity * dt
}

emit_create_particle :: proc(em: Emitter, r: ^random.Generator) -> (particle: Particle) {
    particle.rect.pos = random.eval(em.part_position, r)
    particle.rect.size = random.eval(em.part_size, r)
    particle.origin = em.part_origin
    particle.color = em.part_color // Todo(Dragos): this should also be some sort of distribution. Maybe a gradient
    particle.tex_index = random.eval(em.part_tex_index, r)
    particle.rotation = mathf.Rad(0) // Todo(Dragos): distribution this
    particle.velocity = random.eval(em.part_velocity, r)
    particle.remaining_life = random.eval(em.part_lifetime, r)
    return particle
}

emit_stream :: proc(ps: ^Particle_System, em: core.Value_Or_Ref(Emitter), lifetime: Maybe(random.Distribution(f32)) = nil, r: ^random.Generator) -> (conn: Emitter_Connection) {
    psem: Stream_Emitter
    psem.remaining_lifetime = random.eval(lifetime.(random.Distribution(f32)), r) if lifetime != nil else nil
    psem.emitter = em
    map_insert(&ps._emitters, ps._em_connection_index, psem)
    conn = ps._em_connection_index
    ps._em_connection_index += 1
    return conn
}

update :: proc(ps: ^Particle_System, dt: f32, r: ^random.Generator) {
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
        imdraw.sprite(ps.texture.(imdraw.Texture), ps.texture_rects[particle.tex_index], particle.rect, particle.origin, particle.rotation, particle.color)
    } else do for particle in ps._particles {
        imdraw.quad(particle.rect, particle.origin, particle.rotation, particle.color)
    }     
}
