package mmlow_gpu_backend_glcore3

import gl "vendor:OpenGL"
import "../../../core"
import glcache "../glcached"

// Note(Dragos): Now gpu is dependent on platform
import "../../../platform"


init :: proc() {
    gl.load_up_to(3, 3, core.gl_set_proc_address)
    glcache.init()
    _init_vaos() 
}

teardown :: proc() {
    _destroy_vaos()
}


create_graphics_context :: proc(window: core.Window) {
    ctx_info: core.OpenGL_Context_Info
    ctx_info.major = 3
    ctx_info.minor = 3
    ctx_info.profile = .Core
    platform.create_graphics_context(window, ctx_info)
}







