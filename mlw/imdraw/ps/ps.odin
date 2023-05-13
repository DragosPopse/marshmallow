package mlw_ps

import "../gpu"
import "../core"
import "../media/image"
import "../math"
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
    color: math.Color4f,
    tex: math.Recti,
    rotation: math.Angle,
    velocity: math.Vec2f,
    drag: f32,
}

Emitter_Connection :: distinct int
Affector_Connection :: distinct int

Particle_Emitter_Ref :: distinct ^Particle_Emitter
Particle_System_Emitter :: struct {
    emitter: union {
        Particle_Emitter,
        Particle_Emitter_Ref,
    },
    lifetime: f32,
}

Particle_System :: struct {
    position: math.Vec2f,
    texture: Maybe(imdraw.Texture),
    emitters: map[Emitter_Connection]Particle_System_Emitter, // These will be stream emitters
    _em_connection_index: Emitter_Connection,
}

Particle_Emitter :: struct {
    part_type: ^Particle_Type,
    part_position: math.Distribution(math.Vec2f),
    part_stream_count: int,
    part_velocity: math.Distribution(math.Vec2f),
    part_lifetime: math.Distribution(f32),
    part_texture_index: math.Distribution(int),
}

emit_stream :: proc(ps: ^Particle_System, em: ^Particle_Emitter, lifetime: math.Distribution(f32)) -> (conn: Connection) {

}

update :: proc(ps: ^Particle_System, dt: f32) {
    
}

