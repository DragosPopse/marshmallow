package mmlow_gpu_backend_glcore3

import gl "vendor:OpenGL"
import "../../../core"
import "../../../math"
import "core:fmt"

import glcache "../glcached"

_BUFFER_USAGE_CONV := [core.Buffer_Usage_Hint]u32 {
    .Immutable = gl.STATIC_DRAW,
    .Dynamic = gl.DYNAMIC_DRAW,
    .Stream = gl.STREAM_DRAW,
}

_BUFFER_TYPE_CONV := [core.Buffer_Type]u32 {
    .Vertex = gl.ARRAY_BUFFER,
    .Index = gl.ELEMENT_ARRAY_BUFFER,
}

GLCore3_Buffer :: struct {
    id: core.Buffer,
    handle: u32,
    size: int,
    usage: core.Buffer_Usage_Hint,
    target: u32,
}

_buffers: map[core.Buffer]GLCore3_Buffer

create_buffer :: proc(desc: core.Buffer_Info) ->(buffer: core.Buffer) {
    vbo: u32
    usage := _BUFFER_USAGE_CONV[desc.usage_hint]
    type := _BUFFER_TYPE_CONV[desc.type]
    data := raw_data(desc.data) if len(desc.data) != 0 else nil
    gl.GenBuffers(1, &vbo)
    last_buffer := glcache.BindBuffer(cast(glcache.Buffer_Target)type, vbo)
    gl.BufferData(type, cast(int)desc.size, data, usage)
    glcache.BindBuffer(cast(glcache.Buffer_Target)type, last_buffer) 

    glbuf: GLCore3_Buffer
    glbuf.handle = vbo
    glbuf.id = core.new_buffer_id()
    glbuf.usage = desc.usage_hint
    glbuf.size = auto_cast(desc.size)
    glbuf.target = type
    _buffers[glbuf.id] = glbuf
    return glbuf.id
}

destroy_buffer :: proc(buffer: core.Buffer) {
    assert(buffer in _buffers, "Invalid buffer.")
    glbuf := &_buffers[buffer]
    gl.DeleteBuffers(1, &glbuf.handle)
    delete_key(&_buffers, buffer)
    core.delete_buffer_id(buffer)
}

apply_input_buffers :: proc(buffers: core.Input_Buffers) {
    vao := _get_or_configure_vao(buffers)
    glcache.BindVertexArray(vao)
}

buffer_data :: proc(buffer: core.Buffer, data: []byte) {
    glbuf := &_buffers[buffer]
    assert(glbuf != nil, "Invalid buffer.")
    assert(len(data) <= glbuf.size, "Data size exceeds the buffer size.")
    last_vao := glcache.BindVertexArray(_naked_vao) // Note(Dragos): We do this to not disturb the already configured vaos
    last_buf := glcache.BindBuffer(cast(glcache.Buffer_Target)glbuf.target, glbuf.handle)
    gl.BufferSubData(glbuf.target, 0, len(data), raw_data(data))
    glcache.BindBuffer(auto_cast(glbuf.target), last_buf)
    glcache.BindVertexArray(last_vao)
}