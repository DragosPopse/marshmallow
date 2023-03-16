package glcache

import gl "vendor:wasm/WebGL"
import "core:mem"

Blend_Eq :: enum gl.Enum {
    FUNC_ADD = gl.FUNC_ADD,
    FUNC_SUBTRACT = gl.FUNC_SUBTRACT,
    FUNC_REVERSE_SUBTRACT = gl.FUNC_REVERSE_SUBTRACT,
    MIN = gl.MIN,
    MAX = gl.MAX,
}

Blend_Funcs :: struct {
    src_rgb, dst_rgb, src_alpha, dst_alpha: Blend_Factor,
}

Blend_Equations :: struct {
    mode_rgb, mode_alpha: Blend_Eq,
}

Blend_Factor :: enum gl.Enum {
    ZERO = gl.ZERO,
    ONE = gl.ONE,
    SRC_COLOR = gl.SRC_COLOR,
    ONE_MINUS_SRC_COLOR = gl.ONE_MINUS_SRC_COLOR,
    DST_COLOR = gl.DST_COLOR,
    ONE_MINUS_DST_COLOR = gl.ONE_MINUS_DST_COLOR,
    SRC_ALPHA = gl.SRC_ALPHA,
    ONE_MINUS_SRC_ALPHA = gl.ONE_MINUS_SRC_ALPHA,
    DST_ALPHA = gl.DST_ALPHA,
    ONE_MINUS_DST_ALPHA = gl.ONE_MINUS_DST_ALPHA,
    CONSTANT_COLOR = gl.CONSTANT_COLOR,
    ONE_MINUS_CONSTANT_COLOR = gl.ONE_MINUS_CONSTANT_COLOR,
    CONSTANT_ALPHA = gl.CONSTANT_ALPHA,
    ONE_MINUS_CONSTANT_ALPHA = gl.ONE_MINUS_CONSTANT_ALPHA,
    SRC_ALPHA_SATURATE = gl.SRC_ALPHA_SATURATE,
}

Face :: enum gl.Enum {
    FRONT = gl.FRONT,
    BACK = gl.BACK,
    FRONT_AND_BACK = gl.FRONT_AND_BACK,
}

Texture_Target :: enum gl.Enum {
    TEXTURE_2D = gl.TEXTURE_2D,
    TEXTURE_3D = gl.TEXTURE_3D,
    TEXTURE_2D_ARRAY = gl.TEXTURE_2D_ARRAY,
    TEXTURE_CUBE_MAP = gl.TEXTURE_CUBE_MAP,
}

Buffer_Target :: enum gl.Enum {
    ARRAY_BUFFER = gl.ARRAY_BUFFER,
    COPY_READ_BUFFER = gl.COPY_READ_BUFFER,
    COPY_WRITE_BUFFER = gl.COPY_WRITE_BUFFER,
    ELEMENT_ARRAY_BUFFER = gl.ELEMENT_ARRAY_BUFFER,
    PIXEL_PACK_BUFFER = gl.PIXEL_PACK_BUFFER,
    PIXEL_UNPACK_BUFFER = gl.PIXEL_UNPACK_BUFFER,
    TRANSFORM_FEEDBACK_BUFFER = gl.TRANSFORM_FEEDBACK_BUFFER,
    UNIFORM_BUFFER = gl.UNIFORM_BUFFER,
}

Framebuffer_Target :: enum gl.Enum {
    FRAMEBUFFER = gl.FRAMEBUFFER,
    DRAW_FRAMEBUFFER = gl.DRAW_FRAMEBUFFER,
    READ_FRAMEBUFFER = gl.READ_FRAMEBUFFER,
}

Renderbuffer_Target :: enum gl.Enum {
    RENDERBUFFER = gl.RENDERBUFFER,
}

Capability :: enum gl.Enum {
    BLEND = gl.BLEND,
    CULL_FACE = gl.CULL_FACE,
    DEPTH_TEST = gl.DEPTH_TEST,
}

// Note(Dragos): 64 is the minimum size of the new map implementation, and we have 4 of them, thus 64 * 4 will allocate enough memory
MAP_ELEMENTS_CUM_SIZE :: len(Capability) + len(Buffer_Target) + len(Texture_Target) + 64 * 4

Cache :: struct {
    _maps_memory: [MAP_ELEMENTS_CUM_SIZE * size_of(u32)]byte,
    _arena: mem.Arena,
    
    capabilities: map[Capability]bool, 
    buffers: map[Buffer_Target]gl.Buffer,
    textures: map[Texture_Target]gl.Texture,
    vertex_array: gl.VertexArrayObject,
    program: gl.Program,

    blend_funcs: Blend_Funcs,
    blend_equations: Blend_Equations,

    cull_mode: Face,

    draw_framebuffer: gl.Framebuffer,
    read_framebuffer: gl.Framebuffer,
}

cache: Cache

import "core:fmt"
init :: proc() {
    mem.arena_init(&cache._arena, cache._maps_memory[:])
    map_alloc := mem.arena_allocator(&cache._arena)
    cache.capabilities = make(map[Capability]bool, len(Capability), map_alloc)
    cache.buffers = make(map[Buffer_Target]gl.Buffer, len(Buffer_Target), map_alloc)
    cache.textures = make(map[Texture_Target]gl.Texture, len(Texture_Target), map_alloc)

    for e in Capability {
        cache.capabilities[e] = false
    }
    for e in Buffer_Target {
        cache.buffers[e] = 0
    }
    for e in Texture_Target {
        cache.textures[e] = 0
    }


    fmt.printf("Cache Size: %v\n", size_of(cache))
    fmt.printf("Arena Size: %v\n", size_of(cache._maps_memory))
    fmt.printf("Maps Elem Count: %v\n", MAP_ELEMENTS_CUM_SIZE)

    cache.cull_mode = .BACK
    cache.blend_funcs = {.ZERO, .ZERO, .ZERO, .ZERO}
    cache.blend_equations = {.FUNC_ADD, .FUNC_ADD}

}

enable_or_disable :: proc(cap: Capability, enable: bool) -> (last: bool) {
    if enable do return Enable(cap) 
    else do return Disable(cap)
}

Enable :: proc(cap: Capability) -> (last: bool) {
    last = cache.capabilities[cap]
    if !last {
        gl.Enable(cast(gl.Enum)cap)
    }
    return last
}

Disable :: proc(cap: Capability) -> (last: bool) {
    last = cache.capabilities[cap]
    if !last {
        gl.Disable(cast(gl.Enum)cap)
    }
    return last
}

BindBuffer :: proc(target: Buffer_Target, buffer: gl.Buffer) -> (last: gl.Buffer) {
    last = cache.buffers[target]
    if buffer != last {
        gl.BindBuffer(cast(gl.Enum)target, buffer)
        cache.buffers[target] = buffer
    }
    return last
}

BindVertexArray :: proc(array: gl.VertexArrayObject) -> (last: gl.VertexArrayObject) {
    last = cache.vertex_array
    if last != array {
        gl.BindVertexArray(array)
        cache.vertex_array = array
    }
    return last
}


BlendFuncSeparate :: proc(src_rgb, dst_rgb, src_alpha, dst_alpha: Blend_Factor) -> (last_blend: Blend_Funcs) {
    last_blend = cache.blend_funcs
    current_blend := Blend_Funcs{src_rgb, dst_rgb, src_alpha, dst_alpha}
    if last_blend != current_blend {
        gl.BlendFuncSeparate(cast(gl.Enum)src_rgb, cast(gl.Enum)dst_rgb, cast(gl.Enum)src_alpha, cast(gl.Enum)dst_alpha)
        cache.blend_funcs = current_blend
    }
    return last_blend
}

BlendEquationSeparate :: proc(mode_rgb, mode_alpha: Blend_Eq) -> (last_equations: Blend_Equations) {
    last_equations = cache.blend_equations
    current_equations := Blend_Equations{mode_rgb, mode_alpha}
    if last_equations != current_equations {
        fmt.printf("BlendEquationSeparate is still not added in vendor:webgl")
        //gl.BlendEquationSeparate(cast(gl.Enum)mode_rgb, cast(gl.Enum)mode_alpha)
        cache.blend_equations = current_equations
    }
    return last_equations
}

CullFace :: proc(mode: Face) -> (last_mode: Face) {
    last_mode = cache.cull_mode
    if mode != last_mode {
        gl.CullFace(cast(gl.Enum)mode)
        cache.cull_mode = mode
    }
    return last_mode
}

UseProgram :: proc(program: gl.Program) -> (last_program: gl.Program) {
    last_program = cache.program 
    if program != last_program {
        gl.UseProgram(program)
        cache.program = program
    }
    return last_program
}

BindTexture :: proc(target: Texture_Target, texture: gl.Texture) -> (last_texture: gl.Texture) {
    last_texture = cache.textures[target]
    if last_texture != texture {
        gl.BindTexture(cast(gl.Enum)target, texture)
        cache.textures[target] = texture
    }
    return last_texture
}

BindFramebuffer :: proc(target: Framebuffer_Target, framebuffer: gl.Framebuffer) -> (last_draw_framebuffer, last_read_framebuffer: gl.Framebuffer) {
    last_draw_framebuffer = cache.draw_framebuffer
    last_read_framebuffer = cache.read_framebuffer

    switch target {
        case .FRAMEBUFFER: if cache.draw_framebuffer != framebuffer || cache.read_framebuffer != framebuffer {
            gl.BindFramebuffer(cast(gl.Enum)target, cast(gl.Buffer)framebuffer)
            cache.draw_framebuffer, cache.read_framebuffer = framebuffer, framebuffer
        }

        case .DRAW_FRAMEBUFFER: if cache.draw_framebuffer != framebuffer {
            gl.BindFramebuffer(cast(gl.Enum)target, cast(gl.Buffer)framebuffer)
            cache.draw_framebuffer = framebuffer
        }

        case .READ_FRAMEBUFFER: if cache.read_framebuffer != framebuffer {
            gl.BindFramebuffer(cast(gl.Enum)target, cast(gl.Buffer)framebuffer)
            cache.read_framebuffer = framebuffer
        }
    }
    
    return last_draw_framebuffer, last_read_framebuffer
}
