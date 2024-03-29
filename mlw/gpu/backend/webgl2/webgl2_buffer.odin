package mmlow_gpu_backend_webgl2

import gl "vendor:wasm/WebGL"
import "../../../core"
import "../../../math"
import "core:fmt"

import glcache "../webglcached"

_BUFFER_USAGE_CONV := [core.Buffer_Usage_Hint]gl.Enum {
    .Immutable = gl.STATIC_DRAW,
    .Dynamic = gl.DYNAMIC_DRAW,
    .Stream = gl.STREAM_DRAW,
}

_BUFFER_TYPE_CONV := [core.Buffer_Type]gl.Enum {
    .Vertex = gl.ARRAY_BUFFER,
    .Index = gl.ELEMENT_ARRAY_BUFFER,
}

WebGL2_Buffer :: struct {
    id: core.Buffer,
    handle: gl.Buffer,
    size: int,
    usage: core.Buffer_Usage_Hint,
    target: gl.Enum,
}

_buffers: map[core.Buffer]WebGL2_Buffer
_instanced_call := false

create_buffer :: proc(desc: core.Buffer_Info) ->(buffer: core.Buffer) {
    vbo: gl.Buffer
    usage := _BUFFER_USAGE_CONV[desc.usage_hint]
    type := _BUFFER_TYPE_CONV[desc.type]
    data := raw_data(desc.data) if len(desc.data) != 0 else nil
    vbo = gl.CreateBuffer()
    last_buffer := glcache.BindBuffer(cast(glcache.Buffer_Target)type, vbo)
    gl.BufferData(type, cast(int)desc.size, data, usage)
    glcache.BindBuffer(cast(glcache.Buffer_Target)type, last_buffer) 

    glbuf: WebGL2_Buffer
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
    gl.DeleteBuffer(glbuf.handle)
    delete_key(&_buffers, buffer)
    core.delete_buffer_id(buffer)
}

_use_indexed := false
apply_input_buffers :: proc(buffers: core.Input_Buffers) {
    assert(_current_pipeline != nil, "Invalid pipeline.")

    glcache.BindVertexArray(cast(gl.VertexArrayObject)_naked_vao)
    
    layout := &_current_pipeline.layout

    // Bind index buffer if it exists
    if index, found := buffers.index.?; found {
        assert(index in _buffers, "Cannot find index buffer.")
        //fmt.printf("Index Buffer: %v\n", _buffers[index].handle)
        _use_indexed = true
        // Note(Dragos): glcache doesn't seem to work for webgl. Need testing
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, _buffers[index].handle)
    } else {
        _use_indexed = false
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0)
    }

    // Note(Dragos): check the usage and optimization of this loop format

    // Bind attributes and buffers to the VAO
    current_vbo := gl.Buffer(0)
    for attr, i in layout.attrs do if attr.format != .Invalid {
        buf := buffers.buffers[attr.buffer_index]
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
                _instanced_call = true
        }
        glcache.BindBuffer(.ARRAY_BUFFER, vbo)
        current_vbo = vbo
        gl.VertexAttribPointer(
            i32(i), 
            _ATTR_SIZE_CONV[attr.format], _ATTR_TYPE_CONV[attr.format], 
            false, 
            cast(int)buffer_layout.stride, attr.offset)

        gl.EnableVertexAttribArray(i32(i)) // Note(Dragos): This call should also be cached
        gl.VertexAttribDivisor(u32(i), divisor)
    } else do break


   
}


buffer_data :: proc(buffer: core.Buffer, data: []byte) {
    glbuf := &_buffers[buffer]
    assert(glbuf != nil, "Invalid buffer.")
    assert(len(data) <= glbuf.size, "Data size exceeds the buffer size.")
    last_buf := glcache.BindBuffer(cast(glcache.Buffer_Target)glbuf.target, glbuf.handle)
    gl.BufferSubData(glbuf.target, 0, len(data), raw_data(data))
    glcache.BindBuffer(auto_cast(glbuf.target), last_buf)
}