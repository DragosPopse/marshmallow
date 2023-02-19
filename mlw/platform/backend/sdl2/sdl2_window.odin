package highland_platform_backend_sdl2

import sdl "vendor:sdl2"
import "core:strings"
import "core:c"
import "../../../core"

when ODIN_OS == .Windows {
    import win32 "core:sys/windows"
}




/*
// Note(Dragos): The new dynamic context system makes the startup more complicated. We should avoid this
create_graphics_context :: proc(info: core.Graphics_Info) {
    sdlwin := _get_sdl2_window(window)
    width, height: i32
    window_flags: sdl.WindowFlags
    title := sdl.GetWindowTitle(sdlwin.handle)
    sdl.GetWindowSize(sdlwin.handle, &width, &height)

    last_handle := sdlwin.handle

    switch context_info in info {
        case core.OpenGL_Context_Info: {
            window_flags += sdl.WINDOW_OPENGL
            // Note(Dragos): I had some problems with the SDL context creation on windows.
            when ODIN_OS == .Windows {
                sdlwin.handle = sdl.CreateWindow(title, sdl.WINDOWPOS_CENTERED, sdl.WINDOWPOS_CENTERED, width, height, window_flags)
                dummycontext := sdl.GL_CreateContext(_window.handle)
                profile: i32
                switch context_info.profile {
                    case .Compatibility: 
                        profile = win32.WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB
                    case .ES: 
                        //ES not supported by windows. Make it core
                        profile = win32.WGL_CONTEXT_CORE_PROFILE_BIT_ARB
                    case .Core: 
                        profile = win32.WGL_CONTEXT_CORE_PROFILE_BIT_ARB
                }
                gl33_attribs := [?]i32 {
                    win32.WGL_CONTEXT_MAJOR_VERSION_ARB, cast(i32)context_info.major,
                    win32.WGL_CONTEXT_MINOR_VERSION_ARB, cast(i32)context_info.minor,
                    win32.WGL_CONTEXT_PROFILE_MASK_ARB, profile,
                    0,
                }
                syswm: sdl.SysWMinfo
                sdl.GetVersion(&syswm.version)
                sdl.GetWindowWMInfo(sdlwin.handle, &syswm)
                win32.gl_set_proc_address(&win32.wglCreateContextAttribsARB, "wglCreateContextAttribsARB")
                glcontext: SDL2_GL_Context
                glcontext.handle = win32.wglCreateContextAttribsARB(cast(win32.HDC)syswm.info.win.hdc, nil, &gl33_attribs[0])
                sdl.GL_MakeCurrent(sdlwin.handle, cast(sdl.GLContext)glcontext.handle)
                sdl.GL_DeleteContext(dummycontext)
                sdlwin.graphics_context = glcontext
            } else {
                // On other platforms, just set the attributes and recreate the window
                profile: sdl.GLprofile
                switch context_info.profile {
                    case .Compatibility: 
                        profile = .COMPATIBILITY
                    case .ES: 
                        //ES not supported by windows. Make it core
                        profile = .ES
                    case .Core: 
                        profile = .CORE
                }
                sdl.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, cast(i32)context_info.major)
                sdl.GL_SetAttribute(.CONTEXT_MINOR_VERSION, cast(i32)context_info.minor)
                sdl.GL_SetAttribute(.CONTEXT_PROFILE_MASK, cast(i32)sdl.GLprofile.CORE)
                sdlwin.handle = sdl.CreateWindow(title, sdl.WINDOWPOS_CENTERED, sdl.WINDOWPOS_CENTERED, width, height, window_flags)
                glcontext: SDL2_GL_Context
                glcontext.handle = sdl.GL_CreateContext(sdlwin.handle)
                sldwin.graphics_context = glcontext
            }
        }
    }

    sdl.DestroyWindow(last_handle)
}
*/
