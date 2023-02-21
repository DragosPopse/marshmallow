package glcache

import gl "vendor:OpenGL"
import "core:mem"

Blend_Eq :: enum u32 {
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

Blend_Factor :: enum u32 {
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

Face :: enum u32 {
    FRONT = gl.FRONT,
    BACK = gl.BACK,
    FRONT_AND_BACK = gl.FRONT_AND_BACK,
}

Polygon_Mode :: enum u32 {
    FILL = gl.FILL,
    POINT = gl.POINT,
    LINE = gl.LINE,
}

Texture_Target :: enum u32 {
    TEXTURE_1D = gl.TEXTURE_1D,
    TEXTURE_2D = gl.TEXTURE_1D,
    TEXTURE_3D = gl.TEXTURE_3D,
    TEXTURE_1D_ARRAY = gl.TEXTURE_1D_ARRAY,
    TEXTURE_2D_ARRAY = gl.TEXTURE_2D_ARRAY,
    TEXTURE_RECTANGLE = gl.TEXTURE_RECTANGLE,
    TEXTURE_CUBE_MAP = gl.TEXTURE_CUBE_MAP,
    TEXTURE_CUBE_MAP_ARRAY = gl.TEXTURE_CUBE_MAP_ARRAY,
    TEXTURE_BUFFER = gl.TEXTURE_BUFFER,
    TEXTURE_2D_MULTISAMPLE = gl.TEXTURE_2D_MULTISAMPLE,
    TEXTURE_2D_MULTISAMPLE_ARRAY = gl.TEXTURE_2D_MULTISAMPLE_ARRAY,
}

Buffer_Target :: enum u32 {
    ARRAY_BUFFER = gl.ARRAY_BUFFER,
    ATOMIC_COUNTER_BUFFER = gl.ATOMIC_COUNTER_BUFFER,
    COPY_READ_BUFFER = gl.COPY_READ_BUFFER,
    COPY_WRITE_BUFFER = gl.COPY_WRITE_BUFFER,
    DISPATCH_INDIRECT_BUFFER = gl.DISPATCH_INDIRECT_BUFFER,
    DRAW_INDIRECT_BUFFER = gl.DRAW_INDIRECT_BUFFER,
    ELEMENT_ARRAY_BUFFER = gl.ELEMENT_ARRAY_BUFFER,
    PIXEL_PACK_BUFFER = gl.PIXEL_PACK_BUFFER,
    PIXEL_UNPACK_BUFFER = gl.PIXEL_UNPACK_BUFFER,
    QUERY_BUFFER = gl.QUERY_BUFFER,
    SHADER_STORAGE_BUFFER = gl.SHADER_STORAGE_BUFFER,
    TEXTURE_BUFFER = gl.TEXTURE_BUFFER,
    TRANSFORM_FEEDBACK_BUFFER = gl.TRANSFORM_FEEDBACK_BUFFER,
    UNIFORM_BUFFER = gl.UNIFORM_BUFFER,
}

Framebuffer_Target :: enum u32 {
    FRAMEBUFFER = gl.FRAMEBUFFER,
    DRAW_FRAMEBUFFER = gl.DRAW_FRAMEBUFFER,
    READ_FRAMEBUFFER = gl.READ_FRAMEBUFFER,
}

Renderbuffer_Target :: enum u32 {
    RENDERBUFFER = gl.RENDERBUFFER,
}

Capability :: enum u32 {
    ALPHA_TEST = gl.ALPHA_TEST,
    AUTO_NORMAL = gl.AUTO_NORMAL,
    BLEND = gl.BLEND,
    CLIP_PLANE0 = gl.CLIP_PLANE0,
    CLIP_PLANE1 = gl.CLIP_PLANE1,
    CLIP_PLANE2 = gl.CLIP_PLANE2,
    CLIP_PLANE3 = gl.CLIP_PLANE3,
    CLIP_PLANE4 = gl.CLIP_PLANE4,
    CLIP_PLANE5 = gl.CLIP_PLANE5,
    COLOR_LOGIC_OP = gl.COLOR_LOGIC_OP,
    COLOR_MATERIAL = gl.COLOR_MATERIAL,
    COLOR_SUM = gl.COLOR_LOGIC_OP,
    COLOR_TABLE = gl.COLOR_LOGIC_OP,
    CONVOLUTION_1D = gl.CONVOLUTION_1D,
    CONVOLUTION_2D = gl.CONVOLUTION_2D,
    CULL_FACE = gl.CULL_FACE,
    DEPTH_TEST = gl.DEPTH_TEST,
    DITHER = gl.DITHER,
    FOG = gl.FOG,
    HISTOGRAM = gl.HISTOGRAM,
    INDEX_LOGIC_OP = gl.INDEX_LOGIC_OP,
    LIGHT0 = gl.LIGHT0,
    LIGHT1 = gl.LIGHT1,
    LIGHT2 = gl.LIGHT2,
    LIGHT3 = gl.LIGHT3,
    LIGHT4 = gl.LIGHT4,
    LIGHT5 = gl.LIGHT5,
    LIGHT6 = gl.LIGHT6,
    LIGHT7 = gl.LIGHT7,
    LIGHTING = gl.LIGHTING,
    LINE_SMOOTH = gl.LINE_SMOOTH,
    LINE_STIPPLE = gl.LINE_STIPPLE,
    MAP1_COLOR_4 = gl.MAP1_COLOR_4,
    MAP1_INDEX = gl.MAP1_INDEX,
    MAP1_NORMAL = gl.MAP1_NORMAL,
    MAP1_TEXTURE_COORD_1 = gl.MAP1_TEXTURE_COORD_1,
    MAP1_TEXTURE_COORD_2 = gl.MAP1_TEXTURE_COORD_2,
    MAP1_TEXTURE_COORD_3 = gl.MAP1_TEXTURE_COORD_3,
    MAP1_TEXTURE_COORD_4 = gl.MAP1_TEXTURE_COORD_4,
    MAP1_VERTEX_3 = gl.MAP1_VERTEX_3,
    MAP1_VERTEX_4 = gl.MAP1_VERTEX_4,
    MAP2_TEXTURE_COORD_1 = gl.MAP2_TEXTURE_COORD_1,
    MAP2_TEXTURE_COORD_2 = gl.MAP2_TEXTURE_COORD_2,
    MAP2_TEXTURE_COORD_3 = gl.MAP2_TEXTURE_COORD_3,
    MAP2_TEXTURE_COORD_4 = gl.MAP2_TEXTURE_COORD_4,
    MAP2_VERTEX_3 = gl.MAP2_VERTEX_3,
    MAP2_VERTEX_4 = gl.MAP2_VERTEX_4,
    MINMAX = gl.MINMAX,
    MULTISAMPLE = gl.MULTISAMPLE,
    NORMALIZE = gl.NORMALIZE,
    POINT_SMOOTH = gl.POINT_SMOOTH,
    POINT_SPRITE = gl.POINT_SPRITE,
    POLYGON_OFFSET_FILL = gl.POLYGON_OFFSET_FILL,
    POLYGON_OFFSET_LINE = gl.POLYGON_OFFSET_LINE,
    POLYGON_OFFSET_POINT = gl.POLYGON_OFFSET_POINT,
    POLYGON_SMOOTH = gl.POLYGON_SMOOTH,
    POLYGON_STIPPLE = gl.POLYGON_STIPPLE,
    POST_CONVOLUTION_COLOR_TABLE = gl.POST_CONVOLUTION_COLOR_TABLE,
    RESCALE_NORMAL = gl.RESCALE_NORMAL,
    SAMPLE_ALPHA_TO_COVERAGE = gl.SAMPLE_ALPHA_TO_COVERAGE,
    SAMPLE_ALPHA_TO_ONE = gl.SAMPLE_ALPHA_TO_ONE,
    SAMPLE_COVERAGE = gl.SAMPLE_COVERAGE,
    SEPARABLE_2D = gl.SEPARABLE_2D,
    SCISSOR_TEST = gl.SCISSOR_TEST,
    STENCIL_TEST = gl.STENCIL_TEST,
    TEXTURE_1D = gl.TEXTURE_1D,
    TEXTURE_2D = gl.TEXTURE_2D,
    TEXTURE_3D = gl.TEXTURE_3D,
    TEXTURE_CUBE_MAP = gl.TEXTURE_CUBE_MAP,
    TEXTURE_GEN_Q = gl.TEXTURE_GEN_Q,
    TEXTURE_GEN_R = gl.TEXTURE_GEN_R,
    TEXTURE_GEN_S = gl.TEXTURE_GEN_S,
    TEXTURE_GEN_T = gl.TEXTURE_GEN_T,
    VERTEX_PROGRAM_POINT_SIZE = gl.VERTEX_PROGRAM_POINT_SIZE,
    VERTEX_PROGRAM_TWO_SIDE = gl.VERTEX_PROGRAM_TWO_SIDE,
}

// Note(Dragos): 64 is the minimum size of the new map implementation, and we have 4 of them, thus 64 * 4 will allocate enough memory
MAP_ELEMENTS_CUM_SIZE :: len(Capability) + len(Buffer_Target) + len(Texture_Target) + len(Face) + 64 * 4

Cache :: struct {
    _maps_memory: [MAP_ELEMENTS_CUM_SIZE * size_of(u32)]byte,
    _arena: mem.Arena,
    
    capabilities: map[Capability]bool, 
    buffers: map[Buffer_Target]u32,
    textures: map[Texture_Target]u32,
    polygon_mode: map[Face]Polygon_Mode,
    vertex_array: u32,
    program: u32,

    blend_funcs: Blend_Funcs,
    blend_equations: Blend_Equations,

    cull_mode: Face,

    draw_framebuffer: u32,
    read_framebuffer: u32,
    renderbuffer: u32,
}

cache: Cache

import "core:fmt"
init :: proc() {
    mem.arena_init(&cache._arena, cache._maps_memory[:])
    map_alloc := mem.arena_allocator(&cache._arena)
    cache.capabilities = make(map[Capability]bool, len(Capability), map_alloc)
    cache.buffers = make(map[Buffer_Target]u32, len(Buffer_Target), map_alloc)
    cache.textures = make(map[Texture_Target]u32, len(Texture_Target), map_alloc)
    cache.polygon_mode = make(map[Face]Polygon_Mode, len(Face), map_alloc)

    for e in Capability {
        cache.capabilities[e] = false
    }
    for e in Buffer_Target {
        cache.buffers[e] = 0
    }
    for e in Texture_Target {
        cache.textures[e] = 0
    }
    for e in Face {
        cache.polygon_mode[e] = .FILL
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
        gl.Enable(cast(u32)cap)
    }
    return last
}

Disable :: proc(cap: Capability) -> (last: bool) {
    last = cache.capabilities[cap]
    if !last {
        gl.Disable(cast(u32)cap)
    }
    return last
}

BindBuffer :: proc(target: Buffer_Target, buffer: u32) -> (last: u32) {
    last = cache.buffers[target]
    if buffer != last {
        gl.BindBuffer(cast(u32)target, cast(u32)buffer)
        cache.buffers[target] = buffer
    }
    return last
}

BindVertexArray :: proc(array: u32) -> (last: u32) {
    last = cache.vertex_array
    if last != array {
        gl.BindVertexArray(cast(u32)array)
        cache.vertex_array = array
    }
    return last
}

PolygonMode :: proc(face: Face, mode: Polygon_Mode) -> (last: Polygon_Mode) {
    last = cache.polygon_mode[face]
    if last != mode {
        gl.PolygonMode(cast(u32)face, cast(u32)mode)
        cache.polygon_mode[face] = mode
    }
    return last
}

BlendFuncSeparate :: proc(src_rgb, dst_rgb, src_alpha, dst_alpha: Blend_Factor) -> (last_blend: Blend_Funcs) {
    last_blend = cache.blend_funcs
    current_blend := Blend_Funcs{src_rgb, dst_rgb, src_alpha, dst_alpha}
    if last_blend != current_blend {
        gl.BlendFuncSeparate(cast(u32)src_rgb, cast(u32)dst_rgb, cast(u32)src_alpha, cast(u32)dst_alpha)
        cache.blend_funcs = current_blend
    }
    return last_blend
}

BlendEquationSeparate :: proc(mode_rgb, mode_alpha: Blend_Eq) -> (last_equations: Blend_Equations) {
    last_equations = cache.blend_equations
    current_equations := Blend_Equations{mode_rgb, mode_alpha}
    if last_equations != current_equations {
        gl.BlendEquationSeparate(cast(u32)mode_rgb, cast(u32)mode_alpha)
        cache.blend_equations = current_equations
    }
    return last_equations
}

CullFace :: proc(mode: Face) -> (last_mode: Face) {
    last_mode = cache.cull_mode
    if mode != last_mode {
        gl.CullFace(cast(u32)mode)
        cache.cull_mode = mode
    }
    return last_mode
}

UseProgram :: proc(program: u32) -> (last_program: u32) {
    last_program = cache.program 
    if program != last_program {
        gl.UseProgram(program)
        cache.program = program
    }
    return last_program
}

BindTexture :: proc(target: Texture_Target, texture: u32) -> (last_texture: u32) {
    last_texture = cache.textures[target]
    if last_texture != texture {
        gl.BindTexture(cast(u32)target, texture)
        cache.textures[target] = texture
    }
    return last_texture
}

BindFramebuffer :: proc(target: Framebuffer_Target, framebuffer: u32) -> (last_draw_framebuffer, last_read_framebuffer: u32) {
    last_draw_framebuffer = cache.draw_framebuffer
    last_read_framebuffer = cache.read_framebuffer

    switch target {
        case .FRAMEBUFFER: if cache.draw_framebuffer != framebuffer || cache.read_framebuffer != framebuffer {
            gl.BindFramebuffer(cast(u32)target, framebuffer)
            cache.draw_framebuffer, cache.read_framebuffer = framebuffer, framebuffer
        }

        case .DRAW_FRAMEBUFFER: if cache.draw_framebuffer != framebuffer {
            gl.BindFramebuffer(cast(u32)target, framebuffer)
            cache.draw_framebuffer = framebuffer
        }

        case .READ_FRAMEBUFFER: if cache.read_framebuffer != framebuffer {
            gl.BindFramebuffer(cast(u32)target, framebuffer)
            cache.read_framebuffer = framebuffer
        }
    }
    
    return last_draw_framebuffer, last_read_framebuffer
}

BindRenderbuffer :: proc(target: Renderbuffer_Target, renderbuffer: u32) -> (last_renderbuffer: u32) {
    last_renderbuffer = cache.renderbuffer
    if last_renderbuffer != renderbuffer {
        gl.BindRenderbuffer(cast(u32)target, renderbuffer)
        cache.renderbuffer = renderbuffer
    }

    return last_renderbuffer
}