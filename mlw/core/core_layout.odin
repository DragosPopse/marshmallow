package mmlow_core

import refl "core:reflect"
import "core:fmt"

MAX_VERTEX_ATTRIBUTES :: 16

Vertex_Step_Mode :: enum {
    Per_Vertex,
    Per_Instance,
}

Index_Type :: enum {
    u16,
    u32,
}

Attr_Format :: enum {
    Invalid,

    u8,
    vec2u8,
    vec3u8,
    vec4u8,

    u16,
    vec2u16,
    vec3u16,
    vec4u16,

    u32,
    vec2u32,
    vec3u32,
    vec4u32,

    i16,
    vec2i16,
    vec3i16,
    vec4i16,

    i32,
    vec2i32,
    vec3i32,
    vec4i32,

    f32,
    vec2f32,
    vec3f32,
    vec4f32,
}

Buffer_Layout_Info :: struct {
    stride: uintptr,
    step: Vertex_Step_Mode,
}

Attr_Layout_Info :: struct {
    buffer_index: uint,
    offset: uintptr,
    format: Attr_Format,
}

Layout_Info :: struct {
    buffers: [MAX_SHADERSTAGE_BUFFERS]Buffer_Layout_Info,
    attrs: [MAX_VERTEX_ATTRIBUTES]Attr_Layout_Info,
}

Struct_Layout_Info :: struct {
    type: typeid,
    step: Vertex_Step_Mode,
}

layout_from_structs :: proc(structs: []Struct_Layout_Info) -> (desc: Layout_Info) {
    cur_attr := 0
    for s, i in structs {
        ti := refl.type_info_base(type_info_of(s.type))
        record, ok := ti.variant.(refl.Type_Info_Struct)
        assert(ok, "Only structs allowed.")
        desc.buffers[i].stride = cast(uintptr)ti.size
        desc.buffers[i].step = s.step     

        for type, j in record.types {
            format: Attr_Format
            offset: uintptr
            #partial switch var in type.variant {
                case: {
                    fmt.assertf(false, "Type %v is unsupported for layout_from_struct.\n", var)
                }

                case refl.Type_Info_Array: {
                    assert(var.count <= 4, "Arrays are supported up to 4 elements.")
                    #partial switch elem in refl.type_info_base(var.elem).variant {
                        case: {
                            fmt.assertf(false, "Type %v is unsupported for layout_from_struct.\n", var)
                        }

                        case refl.Type_Info_Integer: {
                            assert(var.elem.size <= 4, "Integers up to 4 bytes are supported.")

                            // Note(Dragos): This is 100% wrong. Fuck me
                            if elem.signed {
                                assert(var.elem.size > 8, "Signed byte not supported.")
                                format = auto_cast(cast(int)Attr_Format.i16 + (4 * var.elem.size / 16) + (var.count - 1))
                            } else {
                                format = auto_cast(cast(int)Attr_Format.u8 + (4 * var.elem.size / 8) + (var.count - 1))
                            }
                        }

                        case refl.Type_Info_Float: {
                            assert(var.elem.size == 4, "Only f32 supported.")
                            format = auto_cast(cast(int)Attr_Format.f32 + (var.count - 1))
                        }
                    }
                }
            }

            desc.attrs[cur_attr].buffer_index = cast(uint)i
            desc.attrs[cur_attr].format = format
            desc.attrs[cur_attr].offset = record.offsets[j]
            cur_attr += 1
        }
    }

    return
}