package mmlow_imdraw

import "../core"
import "../math"
import "../gpu"

_draw_list: Command_Buffer

_in_progress: bool

init :: proc() {
    _draw_list = make_command_buffer()
}

teardown :: proc() {
    delete_command_buffer(&_draw_list)
}

begin :: proc() {
    assert(!_in_progress, "Did you forget to call imdraw.end()?")
    clear_command_buffer(&_draw_list)
    _in_progress = true
}

end :: proc() {
    assert(_in_progress, "Did you forget to call imdraw.begin()?")
    _in_progress = false
}

sprite_vec3 :: proc(texture: gpu.Texture, position: math.Vec3f, rotation: math.Vec3f = {0, 0, 0}, scale: math.Vec3f = {1, 1, 1}, color := math.fWHITE) {
    cmd: Command_Sprite
    cmd.color = color
    cmd.texture = texture
    cmd.transform = {position, rotation, scale}
    push_command(&_draw_list, cmd)
}

sprite_transform :: proc(texture: gpu.Texture, transform: math.Transform, color := math.fWHITE) {
    cmd: Command_Sprite
    cmd.color = color
    cmd.texture = texture
    cmd.transform = transform
    push_command(&_draw_list, cmd)
}

sprite :: proc {
    sprite_vec3,
    sprite_transform,
}