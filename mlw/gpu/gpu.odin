package mmlow_gpu

import "../core"
import "../math"
import "core:slice"

make_texture_data_from_gradient :: proc(gradient: math.Gradient, width: int, allocator := context.allocator) -> (data: []byte) {
    Pixel :: [4]byte
    pixels := make([]Pixel, width, allocator)
    for pixel, i in &pixels {
        pixel.rgb = auto_cast math.gradient_evaluate(gradient, f32(i) / f32(width - 1))
        pixel.a = 0xFF
    }
    return slice.to_bytes(pixels)
}