package highland_gfx_command

Command_Base :: struct {
    color: Color,
}

Command_Line :: struct {
    using base: Command_Base,
    start, end: Vec3f,
}

Command_Quad :: struct {
    using base: Command_Base,
    transform: Transform3D,
}

Command_Sprite :: struct {
    using base: Command_Base,
    transform: Transform3D,
    texture: ^Texture,
}

Command_Vertex_Array :: struct {
    using base: Command_Base,
}

Command :: union {
    Command_Line,
    Command_Quad,
    Command_Sprite,
}

