package mmlow_image 

import "core:fmt"
import "core:c"
import "core:slice" 
import "core:strings"


// TODO: Remove requirement for STB, use core:image/png
//import stbi "vendor:stb/image"

import "../math"


Image :: struct {
    pixels: []math.Colorb,
    size: [2]int,
}

/*
load_image_from_file :: proc(path: string, allocator := context.allocator) -> (img: Image, ok: bool) {
 
    stbi.set_flip_vertically_on_load(1)
    width, height, channels: c.int
    cpath := strings.clone_to_cstring(path, context.temp_allocator)
    data := stbi.load(cpath, &width, &height, &channels, 4)
    defer if data != nil do stbi.image_free(data)
    if data == nil {
        return img, false
    }
    sliceData := slice.from_ptr(data, int(width * height * channels))
    reinterpret := slice.reinterpret([]math.Colorb, sliceData)
    img.pixels = slice.clone(reinterpret, allocator)
    img.size.x = cast(int)width 
    img.size.y = cast(int)height
    return img, true
    
}
*/
load_image_from_file :: proc(path: string, allocator := context.allocator) -> (img: Image, ok: bool) {
    panic("Image loading not currently supported")
}

delete_image :: proc(img: Image, allocator := context.allocator) {
    context.allocator = allocator
    delete(img.pixels)
}

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

