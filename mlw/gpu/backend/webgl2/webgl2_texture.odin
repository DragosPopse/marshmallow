package mmlow_gpu_backend_webgl2

import gl "vendor:wasm/WebGL"
import "../../../core"
import "../../../math"
import glcache "../webglcached"
import "core:strings"
import "core:fmt"

_TEXTURE_TARGET_CONV := [core.Texture_Type]gl.Enum {
    .Invalid = 0,
    .Texture2D = gl.TEXTURE_2D,
    .Texture3D = gl.TEXTURE_3D,
    .Cubemap = gl.TEXTURE_CUBE_MAP,
}

_WRAP_CONV := [core.Texture_Wrap_Mode]gl.Enum {
    .Repeat = gl.REPEAT,
    .Clamp_To_Edge = gl.REPEAT,
    .Clamp_To_Border = gl.REPEAT, // border clamp not supported 
    .Mirrored_Repeat = gl.MIRRORED_REPEAT,
    .Mirror_Clamp_To_Edge = gl.MIRRORED_REPEAT,
}

_MINFILTER_CONV := [core.Texture_Min_Filter]gl.Enum {
    .Nearest = gl.NEAREST,
    .Linear = gl.LINEAR,
    .Nearest_Mip_Nearest = gl.NEAREST_MIPMAP_NEAREST,
    .Linear_Mip_Nearest = gl.LINEAR_MIPMAP_NEAREST,
    .Nearest_Mip_Linear = gl.NEAREST_MIPMAP_LINEAR,
    .Linear_Mip_Linear = gl.LINEAR_MIPMAP_LINEAR,
}

_MAGFILTER_CONV := [core.Texture_Mag_Filter]gl.Enum {
    .Nearest = gl.NEAREST,
    .Linear = gl.LINEAR,
}

WebGL2_Texture :: struct {
    handle: gl.Texture,
    id: core.Texture,
    target: gl.Enum,
    type: core.Texture_Type,
    render_target: bool,
    size: [3]int,
}

_textures: map[core.Texture]WebGL2_Texture 

create_texture :: proc(desc: core.Texture_Info) -> (texture: core.Texture) {
    assert(desc.type != .Invalid, "Invalid texture type.")
    target := _TEXTURE_TARGET_CONV[desc.type]
    handle := gl.CreateTexture()
    last_texture := glcache.BindTexture(cast(glcache.Texture_Target)target, handle)
    
    // Note(Dragos): Implement the other types
    assert(desc.type == .Texture2D, "Only Texture2D implemented.")
    if desc.type == .Texture2D {
        assert(desc.format != .Invalid, "Invalid pixel format. Did you forget to set up texture_info.format?")
        internal_format: gl.Enum
        format, data_type: gl.Enum
        switch desc.format {
            case .Invalid: // already asserted

            case .A8: {
                fmt.assertf(len(desc.data) == desc.size.x * desc.size.y * 1 || desc.data == nil, "Texture size and data mismatch. Expected %v, got %v", desc.size.x * desc.size.y, len(desc.data))
                internal_format = gl.ALPHA
                format = gl.ALPHA
                data_type = gl.UNSIGNED_BYTE
            }

            case .RGBA8:
                assert(len(desc.data) == desc.size.x * desc.size.y * 4 || desc.data == nil, "Texture size and data mismatch")
                internal_format = gl.RGBA
                format = gl.RGBA
                data_type = gl.UNSIGNED_BYTE
            case .RGB8:
                assert(len(desc.data) == desc.size.x * desc.size.y * 3 || desc.data == nil, "Texture size and data mismatch")
                internal_format = gl.RGB
                format = gl.RGB
                data_type = gl.UNSIGNED_BYTE
            case .DEPTH24_STENCIL8: 
                // Todo(Dragos): Assert texture size and data mismatch
                internal_format = gl.DEPTH24_STENCIL8
                format = gl.DEPTH_STENCIL
                data_type = gl.UNSIGNED_INT_24_8
        }
        gl.TexImage2D(target, 0, 
            internal_format, 
            cast(i32)desc.size.x, cast(i32)desc.size.y, 
            0,
            format, 
            data_type, len(desc.data), raw_data(desc.data),
        )
    }
    
    if desc.generate_mipmap do gl.GenerateMipmap(target)
    gl.TexParameteri(target, gl.TEXTURE_WRAP_S, cast(i32)_WRAP_CONV[desc.wrap.x])
    gl.TexParameteri(target, gl.TEXTURE_WRAP_T, cast(i32)_WRAP_CONV[desc.wrap.y])
    gl.TexParameteri(target, gl.TEXTURE_MIN_FILTER, cast(i32)_MINFILTER_CONV[desc.min_filter])
    gl.TexParameteri(target, gl.TEXTURE_MAG_FILTER, cast(i32)_MAGFILTER_CONV[desc.mag_filter])
    
    glcache.BindTexture(cast(glcache.Texture_Target)target, last_texture)
    gltex: WebGL2_Texture
    gltex.handle = handle
    gltex.id = core.new_texture_id()
    gltex.target = target
    gltex.type = desc.type
    gltex.render_target = desc.render_target
    gltex.size = desc.size
    _textures[gltex.id] = gltex
    return gltex.id
}

destroy_texture :: proc(texture: core.Texture) {
    gltex := &_textures[texture]
    gl.DeleteTexture(gltex.handle)
    core.delete_texture_id(texture)
    delete_key(&_textures, texture)
}

apply_input_textures :: proc(textures: core.Input_Textures) {
    shader := _current_pipeline.shader
    current_tex_unit := u32(0)
    for s, stage_i in shader.stages {
        if stage, valid := s.?; valid {
            for i := 0; i < stage.textures_count; i += 1 {
                tex := &stage.textures[i]
                gltex := &_textures[textures.textures[stage_i][i]]

                assert(gltex != nil, "Texture not found.")
                assert(gltex.target == tex.target, "Target mismatch.")
                // Note(Dragos): The glcache doesn't implement BindTexture properly
                gl.ActiveTexture(gl.TEXTURE0 + cast(gl.Enum)current_tex_unit)
                gl.BindTexture(gltex.target, gltex.handle)
                current_tex_unit += 1
            }
        }
    }
}