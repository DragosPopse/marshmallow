package mmlow_gpu_backend_webgl2

import gl "vendor:wasm/WebGL"
import "../../../core"
import "../../../math"

import glcache "../webglcached"

_CULL_CONV := [core.Cull_Mode]gl.Enum {
    .None = 0,
    .Front = gl.FRONT,
    .Back = gl.BACK,
}

_BLEND_OP_CONV := [core.Blend_Op]gl.Enum {
    .Add = gl.FUNC_ADD,
    .Subtract = gl.FUNC_SUBTRACT,
    .Reverse_Subtract = gl.FUNC_REVERSE_SUBTRACT,
}

_BLEND_FACTOR_CONV := [core.Blend_Factor]gl.Enum {
    .Zero = gl.ZERO,
    .One = gl.ONE,
    .Src_Color = gl.SRC_COLOR,
    .One_Minus_Src_Color = gl.ONE_MINUS_SRC_COLOR,
    .Src_Alpha = gl.SRC_ALPHA,
    .One_Minus_Src_Alpha = gl.ONE_MINUS_SRC_ALPHA,
    .Dst_Color = gl.DST_COLOR,
    .One_Minus_Dst_Color = gl.ONE_MINUS_DST_COLOR,
    .Src_Alpha_Saturated = gl.SRC_ALPHA_SATURATE,
    .Blend_Color = gl.BLEND_COLOR,
    .Blend_Src_Alpha = gl.BLEND_SRC_ALPHA,
    .Blend_Dst_Alpha = gl.BLEND_DST_ALPHA,
    .Dst_Alpha = gl.DST_ALPHA,
    .One_Minus_Dst_Alpha = gl.ONE_MINUS_DST_ALPHA,
}

/*
_POLYGON_CONV := [core.Polygon_Mode]u32 {
    .Fill = gl.FILL,
    .Line = gl.LINE,
    .Point = gl.POINT,
}
*/

_PRIMITIVE_CONV := [core.Primitive_Type]gl.Enum {
    .Triangles = gl.TRIANGLES,
    .Lines = gl.LINES,
    .Line_Strip = gl.LINE_STRIP,
}

_INDEX_CONV := [core.Index_Type]gl.Enum {
    .u16 = gl.UNSIGNED_SHORT,
    .u32 = gl.UNSIGNED_INT,
}

WebGL2_Blend :: struct {
    rgb_src: u32,
    rgb_dst: u32,
    rgb_op: u32,
    alpha_src: u32,
    alpha_dst: u32,
    alpha_op: u32,
}

WebGL2_Pipeline :: struct {
    id: core.Pipeline,
    shader: ^WebGL2_Shader,
    cull_mode_enabled: bool,
    cull_mode: u32,
    polygon_mode: u32,
    primitive_type: u32,
    layout: core.Layout_Info,
    index_type: u32,
    depth: Maybe(core.Depth_State), // This is a small workaround until fully supported
    blend: Maybe(WebGL2_Blend), // Note(Dragos): This is weird rn
}

_pipelines: map[core.Pipeline]WebGL2_Pipeline
_current_pipeline: ^WebGL2_Pipeline

create_pipeline :: proc(desc: core.Pipeline_Info) -> (pipeline: core.Pipeline) {
    pipeline = core.new_pipeline_id()
    glpipe: WebGL2_Pipeline
    glpipe.id = pipeline

    glpipe.layout = desc.layout

    assert(desc.shader in _shaders, "Invalid shader ID for pipeline.")
    glpipe.shader = &_shaders[desc.shader]

    glpipe.cull_mode_enabled = desc.cull_mode != .None
    glpipe.cull_mode = _CULL_CONV[desc.cull_mode]
    glpipe.polygon_mode = _POLYGON_CONV[desc.polygon_mode]
    glpipe.primitive_type = _PRIMITIVE_CONV[desc.primitive_type]
    glpipe.index_type = _INDEX_CONV[desc.index_type]
    glpipe.depth = desc.depth
    if blend, found := desc.color.blend.?; found {
        glpipe.blend = WebGL2_Blend {
            rgb_src = _BLEND_FACTOR_CONV[blend.rgb.src_factor],
            rgb_dst = _BLEND_FACTOR_CONV[blend.rgb.dst_factor],
            rgb_op = _BLEND_OP_CONV[blend.rgb.op],
            alpha_src = _BLEND_FACTOR_CONV[blend.alpha.src_factor],
            alpha_dst = _BLEND_FACTOR_CONV[blend.alpha.dst_factor],
            alpha_op = _BLEND_OP_CONV[blend.alpha.op],
        }
    }
    _pipelines[pipeline] = glpipe
    return
}

apply_pipeline :: proc(pipeline: core.Pipeline) {
    assert(pipeline != 0, "Invalid pipeline ID.")
    assert(pipeline in _pipelines, "Pipeline was not found.")
    _current_pipeline = &_pipelines[pipeline]
    glcache.UseProgram(cast(u32)_current_pipeline.shader.program)


    if _current_pipeline.cull_mode_enabled {
        glcache.Enable(.CULL_FACE)
        glcache.CullFace(cast(glcache.Face)_current_pipeline.cull_mode)
    } else {
        glcache.Disable(.CULL_FACE)
    }

    // Note(Dragos): This can be split into front and back polygon modes
    glcache.PolygonMode(.FRONT_AND_BACK, cast(glcache.Polygon_Mode)_current_pipeline.polygon_mode)

    if blend, found := _current_pipeline.blend.?; found {
        glcache.Enable(.BLEND)
        glcache.BlendFuncSeparate(
            auto_cast(blend.rgb_src),
            auto_cast(blend.rgb_dst),
            auto_cast(blend.alpha_src),
            auto_cast(blend.alpha_dst),
        )
        glcache.BlendEquationSeparate(auto_cast(blend.rgb_op), auto_cast(blend.alpha_op))
    } else {
        glcache.Disable(.BLEND)
    }
    glcache.enable_or_disable(.DEPTH_TEST, _current_pipeline.depth != nil)
}

destroy_pipeline :: proc(pipeline: core.Pipeline) {
    assert(pipeline in _pipelines, "Attempted to destroy a pipeline that doesn't exist.")
    if _current_pipeline == &_pipelines[pipeline] do _current_pipeline = nil
    core.delete_pipeline_id(pipeline)
    delete_key(&_pipelines, pipeline)
}