package highland_platform_backend_sdl2

import sdl "vendor:sdl2"
import "../../../core"
import "core:strings"

when ODIN_OS == .Windows {
    import win32 "core:sys/windows"
}

GL_Context :: struct {
    handle: rawptr,
}

Graphics_Context :: union {
    GL_Context,
}

// Note(Dragos): Maybe this should be a handle too
Window :: struct {
    handle: ^sdl.Window,
    graphics_context: Graphics_Context,
} 


_GL_PROFILE_CONV := [core.OpenGL_Profile]i32 {
    .Compatibility = cast(i32)sdl.GLprofile.COMPATIBILITY,
    .Core = cast(i32)sdl.GLprofile.CORE,
    .ES = cast(i32)sdl.GLprofile.ES,
}

@(private = "package") _window: Window

get_backend_window :: proc() -> rawptr {
    return &_window
}

init :: proc(info: core.Platform_Info) {
    core.gl_set_proc_address = sdl.gl_set_proc_address
    window_flags: sdl.WindowFlags
    ctitle := strings.clone_to_cstring(info.window.title, context.temp_allocator)
    use_opengl := false
    switch var in info.graphics.variant {
        case core.OpenGL_Info: {
            if info.graphics.debug {
                sdl.GL_SetAttribute(.CONTEXT_FLAGS, cast(i32)sdl.GLcontextFlag.DEBUG_FLAG)
            }
            sdl.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, cast(i32)var.major)
            sdl.GL_SetAttribute(.CONTEXT_MINOR_VERSION, cast(i32)var.minor)
            sdl.GL_SetAttribute(.CONTEXT_PROFILE_MASK, _GL_PROFILE_CONV[var.profile])
            sdl.GL_SetAttribute(.BUFFER_SIZE, cast(i32)info.graphics.color_bits)
            sdl.GL_SetAttribute(.DEPTH_SIZE, cast(i32)info.graphics.depth_bits)
            sdl.GL_SetAttribute(.STENCIL_SIZE, cast(i32)info.graphics.stencil_bits)
            window_flags += sdl.WINDOW_OPENGL
            use_opengl = true
        }
    }

    _window.handle = sdl.CreateWindow(ctitle, sdl.WINDOWPOS_CENTERED, sdl.WINDOWPOS_CENTERED, i32(info.window.size.x), i32(info.window.size.y), window_flags)
    
    if use_opengl {
        _create_gl_context(info.graphics)
    }
}

_create_gl_context :: proc(info: core.Graphics_Info) {
    gl_info := info.variant.(core.OpenGL_Info) // we already know it's opengl

    // Note(Dragos): There seems to be an issue with sdl.GL_SetAttribute
    when ODIN_OS == .Windows {
        dummycontext := sdl.GL_CreateContext(_window.handle)
        context_flags: i32
        if info.debug {
            context_flags |= win32.WGL_CONTEXT_DEBUG_BIT_ARB
        }
        profile: i32
        switch gl_info.profile {
            case .Compatibility: 
                profile = win32.WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB
            case .ES: 
                //ES not supported by windows. Make it core
                profile = win32.WGL_CONTEXT_CORE_PROFILE_BIT_ARB
            case .Core: 
                profile = win32.WGL_CONTEXT_CORE_PROFILE_BIT_ARB
        }
        gl33_attribs := [?]i32 {
            win32.WGL_CONTEXT_MAJOR_VERSION_ARB, cast(i32)gl_info.major,
            win32.WGL_CONTEXT_MINOR_VERSION_ARB, cast(i32)gl_info.minor,
            win32.WGL_CONTEXT_PROFILE_MASK_ARB, profile,
            win32.WGL_CONTEXT_FLAGS_ARB, context_flags,
            // Note(Dragos): These are pixel format things
            //win32.WGL_COLOR_BITS_ARB, cast(i32)info.color_bits,
            //win32.WGL_DEPTH_BITS_ARB, cast(i32)info.depth_bits,
            //win32.WGL_STENCIL_BITS_ARB, cast(i32)info.stencil_bits, 
            0,
        }
        syswm: sdl.SysWMinfo
        sdl.GetVersion(&syswm.version)
        sdl.GetWindowWMInfo(_window.handle, &syswm)
        win32.gl_set_proc_address(&win32.wglCreateContextAttribsARB, "wglCreateContextAttribsARB")
        glcontext := win32.wglCreateContextAttribsARB(cast(win32.HDC)syswm.info.win.hdc, nil, &gl33_attribs[0])
        sdl.GL_MakeCurrent(_window.handle, cast(sdl.GLContext)glcontext)
        sdl.GL_DeleteContext(dummycontext)
    } else {
        // We already have things setup from previous call
        sdl.GL_CreateContext(_window.handle)
    }

    
    if info.vsync do sdl.GL_SetSwapInterval(1)
    else do sdl.GL_SetSwapInterval(0)
}

teardown :: proc() {
    sdl.DestroyWindow(_window.handle)
}

update_window :: proc() {
    // Note(Dragos): This should be per context instead
    when core.GPU_BACKEND_FAMILY == .OpenGL {
        sdl.GL_SwapWindow(_window.handle)
    }
}