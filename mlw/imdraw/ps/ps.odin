package mlw_ps

import "../gpu"
import "../core"
import "../media/image"
import "../math"
import "core:slice"
import "core:math/linalg"
import "core:fmt"

Particle :: struct {
    rect: math.Rectf,
    tex: math.Recti,
    rotation: math.Angle,
    direction: math.Vec2f,
    speed: f32,
    acceleration: f32,
}

Particle_Type :: struct {
    
}

Particle_System :: struct {
    
}

Particle_Emitter :: struct {
    
}

