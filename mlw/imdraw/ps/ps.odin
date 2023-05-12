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
    gradient: math.Gradient,
    tex: math.Recti,
    rotation: math.Angle,
    velocity: math.Vec2f,
    drag: f32,
}

Particle_Type :: struct {
    
}

Particle_System :: struct {

}

Particle_Emitter :: struct {
    
}

