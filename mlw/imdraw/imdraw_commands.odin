package mmlow_imdraw

import "../math" 
import "../core"
import "../gpu"

Command_Base :: struct {
    color: math.Colorf,
}

Command_Line :: struct {
    using base: Command_Base,
    start, end: math.Vec3f,
}

Command_Quad :: struct {
    using base: Command_Base,
    transform: math.Transform,
}

Command_Sprite :: struct {
    using base: Command_Base,
    transform: math.Transform,
    texture: gpu.Texture,
}

Command_Vertex_Array :: struct {
    using base: Command_Base,
}

Command :: union {
    Command_Line,
    Command_Quad,
    Command_Sprite,
}

