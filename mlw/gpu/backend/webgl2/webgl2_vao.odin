package mmlow_gpu_backend_webgl2

// Todo(Dragos): compile this with -vet-extra
import "core:fmt"
import "core:c"
import "core:runtime"
import "core:strings"
import intr "core:intrinsics"
import gl "vendor:wasm/WebGL"
import smolarr "core:container/small_array"

import "../../../core"
import "../../../math"

import glcache "../webglcached"


_ATTR_SIZE_CONV := [core.Attr_Format]int {
    .Invalid = 0,

    .u8 = 1,
    .vec2u8 = 2,
    .vec3u8 = 3,
    .vec4u8 = 4,

    .u16 = 1,
    .vec2u16 = 2,
    .vec3u16 = 3,
    .vec4u16 = 4,

    .u32 = 1,
    .vec2u32 = 2,
    .vec3u32 = 3,
    .vec4u32 = 4,

    .i16 = 1,
    .vec2i16 = 2,
    .vec3i16 = 3,
    .vec4i16 = 4,

    .i32 = 1,
    .vec2i32 = 2,
    .vec3i32 = 3,
    .vec4i32 = 4,

    .f32 = 1,
    .vec2f32 = 2,
    .vec3f32 = 3,
    .vec4f32 = 4,
}

_ATTR_TYPE_CONV := [core.Attr_Format]gl.Enum {
    .Invalid = 0,
    .u8..=.vec4u8 = gl.BYTE,
    .u16..=.vec4u16 = gl.UNSIGNED_SHORT,
    .u32..=.vec4u32 = gl.UNSIGNED_INT,
    .i16..=.vec4i16 = gl.SHORT,
    .i32..=.vec4i32 = gl.INT,
    .f32..=.vec4f32 = gl.FLOAT,
}


// Todo(Dragos): Implement naked VAO later. Not needed soon
@(private = "package") _naked_vao: gl.VertexArrayObject // Used when running out of configurable VAOs.


_init_vaos :: proc() {
    _naked_vao = gl.CreateVertexArray()
}

_destroy_vaos :: proc() {
    gl.DeleteVertexArray(_naked_vao)
}
