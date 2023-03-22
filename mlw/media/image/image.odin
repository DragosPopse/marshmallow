/*
    Implementation based on "core:image". Make sure to import the required packages if you want support for different loaders eg. "core:image/png"
*/
package mlw_media_image

import "core:fmt"
import "core:c"
import "core:slice" 
import "core:strings"
import "core:bytes"
import "../../math"

import "core:image"

Error :: image.Error

Image :: struct {
    using image: ^image.Image,
    using conversion: struct #raw_union {
        rgba_pixels: []math.BColorRGBA,
        rgb_pixels: []math.BColorRGB,
    },
}

load_from_file :: proc(path: string, opts := image.Options{}, allocator := context.allocator) -> (img: Image, err: Error) {
    context.allocator = allocator
    img.image, err = image.load_from_file(path, opts)
    if err != nil do return
    pixels_slice := bytes.buffer_to_bytes(&img.pixels)
    switch img.channels {
        case 3: {
            img.rgb_pixels = slice.reinterpret([]math.BColorRGB, pixels_slice) 
        }

        case 4: {
            img.rgba_pixels = slice.reinterpret([]math.BColorRGBA, pixels_slice)
        }
    }
    return img, err
}

load_from_bytes :: proc(data: []byte, opts := image.Options{}, allocator := context.allocator) -> (img: Image, err: Error) {
    context.allocator = allocator
    img.image, err = image.load_from_bytes(data, opts)
    if err != nil do return
    pixels_slice := bytes.buffer_to_bytes(&img.pixels)
    switch img.channels {
        case 3: {
            img.rgb_pixels = slice.reinterpret([]math.BColorRGB, pixels_slice) 
        }

        case 4: {
            img.rgba_pixels = slice.reinterpret([]math.BColorRGBA, pixels_slice)
        }
    }
    return img, err
}

delete_image :: proc(img: Image, allocator := context.allocator) {
    image.destroy(img.image, allocator)
}

/*
get_pixel_indices :: #force_inline proc(using img: Image, x, y: int) -> math.Colorb {
    return pixels[x * size.x + y]
}

get_pixel_position :: #force_inline proc(using img: Image, position: [2]int) -> math.Colorb {
    return get_pixel_indices(img, position.x, position.y)
}

set_pixel_indices :: #force_inline proc(using img: Image, x, y: int, val: math.Colorb) {
    pixels[x * size.x + y] = val
}

set_pixel_position :: #force_inline proc(using img: Image, position: [2]int, val: math.Colorb) {
    set_pixel_indices(img, position.x, position.y, val)
}

get_pixel :: proc {
    get_pixel_indices,
    get_pixel_position,
}

set_pixel :: proc {
    set_pixel_indices,
    set_pixel_position,
}
*/

