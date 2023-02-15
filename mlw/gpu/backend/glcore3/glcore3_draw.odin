package mmlow_gpu_backend_glcore3

import gl "vendor:OpenGL"
import "../../../core"
import "../../../math"

import glcache "../glcached"

draw :: proc(base_elem: uint, elem_count: uint) {
    assert(_current_pipeline != nil)
    
    if glcache.cache.buffers[.ELEMENT_ARRAY_BUFFER] != 0 { // Note(Dragos): This can be cached as a bool locally. But it's good for cache testing
        // Note(Dragos): Is this correct? Test with base_elem != 0
        // Note(Dragos): Find a way to assert the index type of the used buffer to match the pipeline. We need proper debugging
        gl.DrawElementsBaseVertex(_current_pipeline.primitive_type, cast(i32)elem_count, _current_pipeline.index_type, nil, cast(i32)base_elem)
    } else {
        gl.DrawArrays(_current_pipeline.primitive_type, cast(i32)base_elem, cast(i32)elem_count)
    }
}