//+build !js
package mmlow_gpu_backend_glcore3

// Todo(Dragos): compile this with -vet-extra
import "core:fmt"
import "core:c"
import "core:runtime"
import "core:strings"
import intr "core:intrinsics"
import gl "../../gl"
import smolarr "core:container/small_array"

import "../../../core"
import "../../../math"




_ATTR_SIZE_CONV := [core.Attr_Format]i32 {
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

_ATTR_TYPE_CONV := [core.Attr_Format]u32 {
    .Invalid = 0,
    .u8..=.vec4u8 = gl.BYTE,
    .u16..=.vec4u16 = gl.UNSIGNED_SHORT,
    .u32..=.vec4u32 = gl.UNSIGNED_INT,
    .i16..=.vec4i16 = gl.SHORT,
    .i32..=.vec4i32 = gl.INT,
    .f32..=.vec4f32 = gl.FLOAT,
}

// Note(Dragos): a lot of config names will probably be changed on release
MAX_CONFIGURABLE_VAOS :: #config(MLW_GPU_GL_MAX_CONFIGURABLE_VAOS, 32)


Vao_Queue :: struct {
    vaos: [MAX_CONFIGURABLE_VAOS]u32,
    size: uint,
}

// Todo(Dragos): Implement naked VAO later. Not needed soon
@(private = "package") _naked_vao: u32 // Used when running out of configurable VAOs.
@(private = "file") _vaos: [MAX_CONFIGURABLE_VAOS]u32 
@(private = "file") _configured_vaos: map[core.Input_Buffers]u32
@(private = "file") _vao_queue: Vao_Queue



@(private = "file")
_add_configurable_vao :: #force_inline proc(key: core.Input_Buffers) -> (vao: u32) {
    assert(_vao_queue.size > 0, "Ran out of allocated configurable VAOs.")
    vao = _vao_queue.vaos[_vao_queue.size - 1]
    _vao_queue.size -= 1
    _configured_vaos[key] = vao
    return
}

_get_or_configure_vao :: proc(key: core.Input_Buffers) -> (vao: u32, instanced: bool) {
    assert(_current_pipeline != nil, "Invalid pipeline.")
    if key in _configured_vaos do return _configured_vaos[key]

    vao = _add_configurable_vao(key)
    
    layout := &_current_pipeline.layout

    gl.BindVertexArray(vao)

    // Bind index buffer if it exists
    if index, found := key.index.?; found {
        assert(index in _buffers, "Cannot find index buffer.")
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, _buffers[index].handle)
    } else {
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0)
    }

    // Note(Dragos): check the usage and optimization of this loop format

    // Bind attributes and buffers to the VAO
    current_vbo := u32(0)
    for attr, i in layout.attrs do if attr.format != .Invalid {
        buf := key.buffers[attr.buffer_index]
        assert(buf in _buffers, "Cannot find buffer.")
        glbuf := &_buffers[buf]
        vbo := glbuf.handle
        buffer_layout := layout.buffers[attr.buffer_index]
        divisor: u32
        switch buffer_layout.step {
            case .Per_Vertex: 
                divisor = 0
            case .Per_Instance: 
                divisor = 1
                instanced = true
        }
        gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
        current_vbo = vbo
        gl.VertexAttribPointer(
            u32(i), 
            _ATTR_SIZE_CONV[attr.format], _ATTR_TYPE_CONV[attr.format], 
            gl.FALSE, 
            cast(i32)buffer_layout.stride, attr.offset)

        gl.EnableVertexAttribArray(u32(i)) // Note(Dragos): This call should also be cached
        gl.VertexAttribDivisor(u32(i), divisor)
    } else do break

    

    return vao, instanced
}

_remove_configured_vao :: proc(key: core.Input_Buffers) {
    // Note(Dragos): Maybe the assert can be made into an if. We'll see the usage
    assert(key in _configured_vaos, "Cannot find configured VAO to remove.")
    vao := _configured_vaos[key]
    _vao_queue.vaos[_vao_queue.size] = vao
    _vao_queue.size += 1
    delete_key(&_configured_vaos, key)
}

_init_vaos :: proc() {
    gl.GenVertexArrays(MAX_CONFIGURABLE_VAOS, &_vaos[0])
    gl.GenVertexArrays(1, &_naked_vao)

    _vao_queue.vaos = _vaos
    _vao_queue.size = MAX_CONFIGURABLE_VAOS
}

_destroy_vaos :: proc() {
    gl.DeleteVertexArrays(MAX_CONFIGURABLE_VAOS, &_vaos[0])
    gl.DeleteVertexArrays(1, &_naked_vao)
}
