package mmlow_imdraw

import "../math" 
import "../core"
import "../gpu"

Textured_Vertex :: struct {
    pos: math.Vec3f,
    tex: math.Vec2f,
}

Simple_Vertex :: struct {
    pos: math.Vec3f,
}

Sprite_Uniforms :: struct {
    model: math.Mat4f,
    color: math.Colorf,
}

Camera_Uniforms :: struct {
    view: math.Mat4f,
    projection: math.Mat4f,
}

SPRITE_VERTICES := [?]Textured_Vertex {
    {{-0.5, -0.5, -0.5}, {0.0, 0.0}},
    {{ 0.5, -0.5, -0.5}, {1.0, 0.0}},
    {{ 0.5,  0.5, -0.5}, {1.0, 1.0}},
    {{ 0.5,  0.5, -0.5}, {1.0, 1.0}},
    {{-0.5,  0.5, -0.5}, {0.0, 1.0}},
    {{-0.5, -0.5, -0.5}, {0.0, 0.0}},
}

SQUAD_VERTICES := [?]Simple_Vertex {
    {{-0.5, -0.5, -0.5}},
    {{ 0.5, -0.5, -0.5}},
    {{ 0.5,  0.5, -0.5}},
    {{ 0.5,  0.5, -0.5}},
    {{-0.5,  0.5, -0.5}},
    {{-0.5, -0.5, -0.5}},
}

Command_Base :: struct {
    color: math.Colorf,
    camera: ^math.Camera, // Maybe this can be a pointer
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

