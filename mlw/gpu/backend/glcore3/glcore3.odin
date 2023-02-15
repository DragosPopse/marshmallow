package mmlow_gpu_backend_glcore3

import gl "vendor:OpenGL"
import "../../../core"
import glcache "../glcached"


init :: proc() {
    gl.load_up_to(3, 3, core.gl_set_proc_address)
    glcache.init()
    _init_vaos() 
}

teardown :: proc() {
    _destroy_vaos()
}








