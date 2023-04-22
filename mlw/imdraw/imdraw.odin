package mlw_imdraw

import "mlw:gpu"
import "mlw:core"
import "mlw:media/image"
import "mlw:math"
import "core:slice"
import "core:math/linalg"
import "core:fmt"


/*
    Initialization/Teardown
*/


init :: proc() {
    err: Maybe(string)
    if _shader, err = _create_default_shader(); err != nil {
        fmt.printf("Shader Error: %v\n", err.(string))
    }
    _pipeline = _create_imdraw_pipeline(_shader)
    _input_buffers.buffers[0], _input_buffers.index = _create_imdraw_buffers()
}

teardown :: proc() {

}


/*
    State Changes
*/

set_current_texture :: proc(texture: gpu.Texture) {
    if texture != _current_textures.textures[.Fragment][0] do _flush() // This could work no?
    _current_textures.textures[.Fragment][0] = texture
    _current_textures_info[.Fragment][0] = gpu.texture_info(texture)
    gpu.apply_input_textures(_current_textures)
}

/*
    Rendering
*/

// Note(Dragos): This is a bit goofy for now. I think the renderer could defer everything at the end via draw commands, but this is simple for now
begin :: proc(camera: math.Camera) {
    _buf_idx = 0
    gpu.apply_pipeline(_pipeline)
    gpu.apply_input_buffers(_input_buffers)
    _uniforms.modelview, _uniforms.projection = math.camera_to_mat4f(camera)
    gpu.apply_uniforms_raw(.Vertex, 0, &_uniforms, size_of(_uniforms))
}

end :: proc() {
    _flush()
}


sprite_size :: proc(position: math.Vec2f, size: math.Size2f, tex_rect: math.Recti, color := math.FRGBA_WHITE) {
    _push_quad({position, auto_cast size}, tex_rect, color)
}


sprite_scale :: proc(position: math.Vec2f, scale: math.Scale2f, tex_rect: math.Recti, color := math.FRGBA_WHITE) {
    tex_size_f := math.Vec2f{cast(f32)tex_rect.size.x, cast(f32)tex_rect.size.y}
    _push_quad({position, tex_size_f * auto_cast scale}, tex_rect, color)
}

sprite :: proc {
    sprite_size,
    sprite_scale,
}


/*
    Asset Creation
*/


// Note(Dragos): This should be separated in _from_file, _from_image, _from_bytes
create_texture :: proc(path: string) -> (texture: gpu.Texture) {
    info: gpu.Texture_Info
    info.type = .Texture2D
    info.format = .RGBA8
    info.min_filter = .Nearest
    info.mag_filter = .Nearest
    info.generate_mipmap = false
    img, err := image.load_from_file(path)
    if err != nil {
        fmt.printf("create_sprite_texture error: %v\n", err)
        return 0
    }
    defer image.delete_image(img)
    assert(img.channels == 4, "Only 4 channels textures are supported atm. Just load a png.")
    info.size.xy = {img.width, img.height}
    info.data = slice.to_bytes(img.rgba_pixels)
    return gpu.create_texture(info)
}
