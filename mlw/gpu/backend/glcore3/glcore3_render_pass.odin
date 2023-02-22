package mmlow_gpu_backend_glcore3

import "../../../core"
import "../../../math"

import gl "vendor:OpenGL"
import glcache "../glcached"

Render_Pass :: struct {
    id: core.Render_Pass,
    framebuffer: u32,
    colors_count: int,
    fb_size: [2]i32,
    colors: [core.MAX_COLOR_ATTACHMENTS]^GLCore3_Texture,
    stencil_depth: ^GLCore3_Texture,
}

_current_pass: ^Render_Pass
_passes: map[core.Render_Pass]Render_Pass

create_render_pass :: proc(info: core.Render_Pass_Info) -> (pass: core.Render_Pass) {
    assert(info.colors[0].texture != 0, "A pass needs to have at least 1 color attachment")
    glpass: Render_Pass
    pass = core.new_render_pass_id()
    glpass.id = pass
    fb_size: [2]int

    gl.GenFramebuffers(1, &glpass.framebuffer)
    last_fb, _ := glcache.BindFramebuffer(.FRAMEBUFFER, glpass.framebuffer)
    for attach, i in info.colors do if attach.texture != 0 {
        assert(attach.texture in _textures, "Texture was not found")
        gltex := &_textures[attach.texture]
        assert(gltex.render_target, "Texture must be created with info.render_target = true")
        if i == 0 {
            fb_size.xy = gltex.size.xy
        }
        assert(gltex.size.xy == fb_size, "All color attachments must have the same size.")
        if gltex.type == .Texture2D {
            gl.FramebufferTexture2D(gl.FRAMEBUFFER, u32(gl.COLOR_ATTACHMENT0 + i), gl.TEXTURE_2D, gltex.handle, cast(i32)attach.mip_level)
        } else {
            // Note(Dragos): Figure this out
            panic("Not supported texture type for render target.")
        }

        glpass.colors[i] = gltex
        
    } else do break

    if info.depth_stencil.texture != 0 {
        panic("Not implemented")
    }
    assert(gl.CheckFramebufferStatus(gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE, "Framebuffer creation failed.")
    glcache.BindFramebuffer(.FRAMEBUFFER, last_fb)
    glpass.fb_size.x = cast(i32)fb_size.x
    glpass.fb_size.y = cast(i32)fb_size.y
    return pass
}

destroy_render_pass :: proc(pass: core.Render_Pass) {
    assert(pass in _passes, "Render pass not found.")
    glpass := &_passes[pass]
    gl.DeleteFramebuffers(1, &glpass.framebuffer)
    delete_key(&_passes, pass)
}

begin_render_pass :: proc(pass: core.Render_Pass, action: core.Render_Pass_Action) {
    assert(_current_pass == nil, "Pass currently in progress")
    assert(pass in _passes, "Pass not found.")
    _current_pass = &_passes[pass]
    glcache.BindFramebuffer(.FRAMEBUFFER, _current_pass.framebuffer)
    gl.Viewport(0, 0, _current_pass.fb_size.x, _current_pass.fb_size.y)
    gl.Scissor(0, 0, _current_pass.fb_size.x, _current_pass.fb_size.y) // Note(Dragos): What does this do?
}

begin_default_render_pass :: proc(action: core.Render_Pass_Action, width, height: int) {
    w, h := cast(i32)width, cast(i32)height
    gl.Viewport(0, 0, w, h)
    gl.Scissor(0, 0, w, h)
    glcache.BindFramebuffer(.FRAMEBUFFER, 0)
}

end_render_pass :: proc() {
    assert(_current_pass != nil, "No current pass")
    _current_pass = nil
}