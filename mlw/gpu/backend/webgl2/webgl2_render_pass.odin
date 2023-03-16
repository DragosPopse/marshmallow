package mmlow_gpu_backend_webgl2

import "../../../core"
import "../../../math"

import gl "vendor:wasm/WebGL"
import glcache "../webglcached"

Render_Pass :: struct {
    id: core.Render_Pass,
    framebuffer: u32,
    colors_count: int,
    fb_size: [2]i32,
    num_colors: int,
    depth_stencil: bool,
}

_default_pass: Render_Pass
_current_pass: ^Render_Pass
_passes: map[core.Render_Pass]Render_Pass

create_pass :: proc(info: core.Render_Pass_Info) -> (pass: core.Render_Pass) {
    assert(info.colors[0].texture != 0, "A pass needs to have at least 1 color attachment")
    glpass: Render_Pass
    pass = core.new_render_pass_id()
    glpass.id = pass
    fb_size: [2]int

    gl.GenFramebuffers(1, &glpass.framebuffer)
    last_fb, _ := glcache.BindFramebuffer(.FRAMEBUFFER, glpass.framebuffer)
    for attach, i in info.colors do if attach.texture != 0 {
        glpass.num_colors += 1
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
    } else do break

    if info.depth_stencil.texture != 0 {
        assert(info.depth_stencil.texture in _textures, "Texture not found.")
        gltex := _textures[info.depth_stencil.texture]
        glpass.depth_stencil = true
        gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT, gl.TEXTURE_2D, gltex.handle, 0)
    }
    assert(gl.CheckFramebufferStatus(gl.FRAMEBUFFER) == gl.FRAMEBUFFER_COMPLETE, "Framebuffer creation failed.")
    glcache.BindFramebuffer(.FRAMEBUFFER, last_fb)
    glpass.fb_size.x = cast(i32)fb_size.x
    glpass.fb_size.y = cast(i32)fb_size.y
    _passes[pass] = glpass
    return pass
}

destroy_pass :: proc(pass: core.Render_Pass) {
    assert(pass in _passes, "Render pass not found.")
    glpass := &_passes[pass]
    gl.DeleteFramebuffers(1, &glpass.framebuffer)
    delete_key(&_passes, pass)
}

begin_default_pass :: proc(action: core.Render_Pass_Action, width, height: int) {
    assert(_current_pass == nil, "Cannot being a pass while in another pass")

    w, h := cast(i32)width, cast(i32)height
    _current_pass = &_default_pass
    
    glcache.BindFramebuffer(.FRAMEBUFFER, 0)

    gl.Viewport(0, 0, w, h)
    gl.Scissor(0, 0, w, h)

    clear_color := action.colors[0].action == .Clear
    clear_depth := action.depth.action == .Clear
    clear_stencil := action.stencil.action == .Clear

    clear_mask := u32(0)

    if clear_color {
        val := action.colors[0].value
        gl.ClearColor(val.r, val.g, val.b, val.a)
        clear_mask |= gl.COLOR_BUFFER_BIT
    }

    if clear_depth {
        clear_mask |= gl.DEPTH_BUFFER_BIT
        gl.ClearDepth(cast(f64)action.depth.value)
    }

    if clear_stencil {
        clear_mask |= gl.STENCIL_BUFFER_BIT
        gl.ClearStencil(cast(i32)action.stencil.value)
    }

    if clear_mask != 0 do gl.Clear(clear_mask)  
}

begin_pass :: proc(pass: core.Render_Pass, action: core.Render_Pass_Action) {
    assert(_current_pass == nil, "Pass currently in progress")
    assert(pass in _passes, "Pass not found.")

    _current_pass = &_passes[pass]

    glcache.BindFramebuffer(.FRAMEBUFFER, _current_pass.framebuffer)

    gl.Viewport(0, 0, _current_pass.fb_size.x, _current_pass.fb_size.y)
    gl.Scissor(0, 0, _current_pass.fb_size.x, _current_pass.fb_size.y)

    clear_depth := action.depth.action == .Clear
    clear_stencil := action.depth.action == .Clear

    for i := 0; i < _current_pass.num_colors; i += 1 {
        clear_color := action.colors[i].action == .Clear
        color := action.colors[i].value
        if clear_color do gl.ClearBufferfv(gl.COLOR, i32(i), &color[0])
    }

    if _current_pass.depth_stencil {
        depth_value := action.depth.value
        stencil_value := i32(action.stencil.value)
        if clear_depth && clear_stencil do gl.ClearBufferfi(gl.DEPTH_STENCIL, 0, depth_value, stencil_value)
        else if clear_depth do gl.ClearBufferfv(gl.DEPTH, 0, &depth_value)
        else if clear_stencil do gl.ClearBufferiv(gl.STENCIL, 0, &stencil_value)
    }
}

end_pass :: proc() {
    assert(_current_pass != nil, "No current pass")
    _current_pass = nil
    glcache.BindFramebuffer(.FRAMEBUFFER, 0)
}