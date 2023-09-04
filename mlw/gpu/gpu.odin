package mmlow_gpu

import "../core"
import "../math/mathf"
import "core:slice"

make_texture_data_from_gradient :: proc(gradient: mathf.Gradient, width: int, allocator := context.allocator) -> (data: []byte) {
    Pixel :: [4]byte
    pixels := make([]Pixel, width, allocator)
    for pixel, i in &pixels {
        pixel.rgb = auto_cast math.gradient_evaluate(gradient, f32(i) / f32(width - 1))
        pixel.a = 0xFF
    }
    return slice.to_bytes(pixels)
}

create_texture_from_gradient :: proc(gradient: mathf.Gradient, width: int) -> (texture: Texture) { 
    info: Texture_Info
    info.format = .RGBA8
    info.type = .Texture2D
    info.generate_mipmap = false
    info.size.xy = {width, 1}
    info.data = make_texture_data_from_gradient(gradient, width, context.temp_allocator)
    info.min_filter = .Linear
    info.mag_filter = .Linear
    info.wrap.xy = {.Clamp_To_Edge, .Clamp_To_Edge}

    return create_texture(info)
}
