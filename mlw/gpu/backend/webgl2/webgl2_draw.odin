package mmlow_gpu_backend_webgl2

import gl "vendor:wasm/WebGL"
import "../../../core"
import "../../../math"

import glcache "../webglcached"

draw :: proc(base_elem: int, elem_count: int, instance_count: int) {
    assert(_current_pipeline != nil, "Pipeline not set.")

    if instance_count <= 0 do return

    use_indexed := glcache.cache.buffers[.ELEMENT_ARRAY_BUFFER] != 0 // Note(Dragos): This can be cached as a bool locally. But it's good for cache testing
    use_instanced := _instanced_call || instance_count > 1 // Is this chill?
    
    if use_indexed { 
        if use_instanced {
            //gl.DrawElementsInstancedBaseVertex(_current_pipeline.primitive_type, cast(i32)elem_count, _current_pipeline.index_type, nil, cast(i32)instance_count, cast(i32)base_elem)
            gl.DrawElementsInstanced(_current_pipeline.primitive_type, elem_count, _current_pipeline.index_type, base_elem, instance_count)
        } else {
            gl.DrawElements(_current_pipeline.primitive_type, elem_count, _current_pipeline.index_type, nil) // Warn(Dragos): This ignores base_elem
        }
    } else {
        if use_instanced {
            gl.DrawArraysInstanced(_current_pipeline.primitive_type, base_elem, elem_count, instance_count)
        } else {
            gl.DrawArrays(_current_pipeline.primitive_type, base_elem, elem_count)
        }
    }
}