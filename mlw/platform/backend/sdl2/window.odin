package highland_platform_backend_sdl2

import sdl "vendor:sdl2"
import "core:strings"
import "core:c"
import "../../../core"

when ODIN_OS == .Windows {
    import win32 "core:sys/windows"
}

// Note(Dragos): Maybe this should be a handle too
Window :: struct {
    sdl_handle: ^sdl.Window,
}

poll_events :: proc(window: Window) {
    sdlWindow := window.sdl_handle
    ev: sdl.Event 
    for sdl.PollEvent(&ev) {
        #partial switch ev.type {
            case .QUIT: {
                _close_window = true
            }
        }
    }
}

create_window :: proc(title: string, width, height: int) -> (win: Window) {
    using win
    ctitle := strings.clone_to_cstring(title, context.temp_allocator)
    when core.GPU_BACKEND == .glcore3 {
        sdl.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, 3)
        sdl.GL_SetAttribute(.CONTEXT_MINOR_VERSION, 3)
        sdl.GL_SetAttribute(.CONTEXT_PROFILE_MASK, cast(c.int)sdl.GLprofile.CORE)
        window_flags += sdl.WINDOW_OPENGL
    }
    sdl_handle = sdl.CreateWindow(ctitle, sdl.WINDOWPOS_CENTERED, sdl.WINDOWPOS_CENTERED, cast(c.int)width, cast(c.int)height, window_flags)
    
    when core.GPU_BACKEND == .glcore3 && ODIN_OS == .Windows {
        dummycontext := sdl.GL_CreateContext(sdl_handle)
        gl33_attribs := [?]i32 {
            win32.WGL_CONTEXT_MAJOR_VERSION_ARB, 3,
            win32.WGL_CONTEXT_MINOR_VERSION_ARB, 3,
            win32.WGL_CONTEXT_PROFILE_MASK_ARB, win32.WGL_CONTEXT_CORE_PROFILE_BIT_ARB,
            0,
        }
        syswm: sdl.SysWMinfo
        sdl.GetVersion(&syswm.version)
        sdl.GetWindowWMInfo(sdl_handle, &syswm)
        win32.gl_set_proc_address(&win32.wglCreateContextAttribsARB, "wglCreateContextAttribsARB")
        glcontext := win32.wglCreateContextAttribsARB(cast(win32.HDC)syswm.info.win.hdc, nil, &gl33_attribs[0])
        sdl.GL_MakeCurrent(sdl_handle, cast(sdl.GLContext)glcontext)
        sdl.GL_DeleteContext(dummycontext)
    } else {
        glcontext := sdl.GL_CreateContext(sdl_handle)
    }
    
    
    return
}

destroy_window :: proc(win: Window) {
    sdl.DestroyWindow(win.sdl_handle)
}

// Note(Dragos): Should this be in the gfx backend?
swap_buffers :: proc(win: Window) {
    when core.GPU_BACKEND_FAMILY == .OpenGL {
        sdl.GL_SwapWindow(win.sdl_handle) 
    } else {
        #panic("Unsupported GPU_BACKEND_FAMILY")
    }
}

window_should_close :: proc() -> bool {
    return _close_window 
}