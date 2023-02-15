package highland_gfx_command

import colors "../../common/math/color"

push_command_line_vec3 :: proc(buf: ^Command_Buffer, start, end: Vec3f, color := colors.WHITE) {
    push_command(buf, Command_Line{base = {color = color}, start = start, end = end})
}

push_command_line_v :: proc(buf: ^Command_Buffer, x1, y1, z1, x2, y2, z2: f32, color := colors.WHITE) {
    push_command(buf, Command_Line{base = {color = color}, start = {x1, y1, z1}, end = {x2, y2, z2}})
}

push_command_line :: proc {
    push_command_line_vec3,
    push_command_line_v,
}

push_command_quad_transform :: proc(buf: ^Command_Buffer, t: Transform3D, color := colors.WHITE) {
    push_command(buf, Command_Quad{base = {color = color}, transform = t})
}

push_command_quad_vec3 :: proc(buf: ^Command_Buffer, position, rotation, scale: Vec3f, color := colors.WHITE) {
    push_command(buf, Command_Quad{base = {color = color}, transform = {pos = position, rot = rotation, scale = scale}})
}

push_command_quad :: proc {
    push_command_quad_transform,
    push_command_quad_vec3,
}

push_command_sprite_transform :: proc(buf: ^Command_Buffer, texture: ^Texture, transform: Transform3D, color := colors.WHITE) {
    push_command(buf, Command_Sprite{base = {color = color}, transform = transform, texture = texture})
}

push_command_sprite_vec3 :: proc(buf: ^Command_Buffer, texture: ^Texture, position, rotation, scale: Vec3f, color := colors.WHITE) {
    push_command(buf, Command_Sprite{base = {color = color}, texture = texture, transform = {pos = position, rot = rotation, scale = scale}})
}

push_command_sprite :: proc {
    push_command_sprite_transform,
    push_command_sprite_vec3,
}