//+build !js
package mmlow_gpu_backend_glcore3

import gl "vendor:OpenGL"
import "../../../core"
import glcache "../glcached"

// Note(Dragos): Now gpu is dependent on platform
import "../../../platform"

import "core:fmt"

State :: struct {

}


init :: proc() {
    gl.load_up_to(3, 3, core.gl_set_proc_address)
    glcache.init()
    _init_vaos()
    glcache.BindVertexArray(_naked_vao)
    fmt.printf("OpenGL Version: %s\n", gl.GetString(gl.VERSION))
}

teardown :: proc() {
    _destroy_vaos()
}


default_graphics_info :: proc() -> core.Graphics_Info {
    gfx_info: core.Graphics_Info
    gl_info: core.OpenGL_Info

    gl_info.major = 3
    gl_info.minor = 3
    gl_info.profile = .Core

    gfx_info.color_bits = 32
    gfx_info.debug = true when ODIN_DEBUG else false
    gfx_info.depth_bits = 24
    gfx_info.stencil_bits = 8
    gfx_info.variant = gl_info
    
    return gfx_info
}







