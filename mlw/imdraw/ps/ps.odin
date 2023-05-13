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

// Note(Dragos): This is a bit OOP-brained. Should ask for advice to cure my disease

Affector_Proc :: #type proc(this: Affector, particle: ^Particle, dt: f32)

Affector :: struct {
    update: Affector_Proc,
}

Particle :: struct {
    rect: math.Rectf,
    origin: math.Vec2f,
    color: math.Color4f,
    tex: math.Recti,
    rotation: math.Angle,
    velocity: math.Vec2f,
    remaining_life: f32,
    drag: f32,
}

Emitter_Connection :: distinct u64
Affector_Connection :: distinct u64

Particle_Emitter_Ref :: distinct ^Particle_Emitter
Particle_System_Emitter :: struct {
    emitter: core.Value_Or_Ref(Particle_Emitter),
    remaining_lifetime: Maybe(f32),
}

Particle_System :: struct {
    position: math.Vec2f,
    texture: Maybe(imdraw.Texture),
    
    _particles: [dynamic]Particle,
    _emitters: map[Emitter_Connection]Particle_System_Emitter, // These will be stream emitters
    _em_connection_index: Emitter_Connection,
}

Particle_Emitter :: struct {
    part_position: math.Distribution(math.Vec2f),
    part_size: math.Distribution(f32),
    part_origin: math.Vec2f,
    part_stream_count: int,
    part_velocity: math.Distribution(math.Vec2f),
    part_lifetime: math.Distribution(f32),
    part_texture_index: math.Distribution(int),
}

emit_stream :: proc(ps: ^Particle_System, em: core.Value_Or_Ref(Particle_Emitter), lifetime: Maybe(math.Distribution(f32)) = nil, r: ^rand.Rand = nil) -> (conn: Emitter_Connection) {
    psem: Particle_System_Emitter
    psem.remaining_lifetime = math.eval(lifetime.(math.Distribution(f32)), r) if lifetime != nil else nil
    map_insert(&ps._emitters, ps._em_connection_index, psem)
}

update :: proc(ps: ^Particle_System, dt: f32) {
    { // Update emitters
        for em_key, em in &ps._emitters {
            lifetime, has_lifetime := &em.remaining_lifetime.(f32)
            if has_lifetime {
                lifetime^ -= dt
                if lifetime^ <= 0 {
                    delete_key(&ps._emitters, em_key)
                    continue // should i?
                }
            }
            emitter := core.value_or_ref_ptr(&em.emitter)
            
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
            particle.rect.pos += particle.velocity * dt 
        }
    }
}

draw :: proc(ps: ^Particle_System) {
    if ps.texture != nil do for particle in ps._particles {
        imdraw.sprite(ps.texture.(imdraw.Texture), particle.rect, particle.origin, particle.tex, particle.rotation, particle.color)
    } else do for particle in ps._particles {
        imdraw.rect(particle.rect, particle.origin, particle.rotation, particle.color)
    }     
}

