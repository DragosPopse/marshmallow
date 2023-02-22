package mmlow_core

import "../math"

Render_Pass :: distinct u32

MAX_COLOR_ATTACHMENTS :: 4

Attachment_Info :: struct {
    texture: Texture,
    mip_level: int,
    slice: int,
}

Color_Action :: struct {
    action: Render_Pass_Action_Type,
    value: math.Colorf,
}

Depth_Action :: struct {
    action: Render_Pass_Action_Type,
    value: f32,
}

Stencil_Action :: struct {
    action: Render_Pass_Action_Type,
    value: u8,
}

Render_Pass_Action_Type :: enum {
    Clear,
    Load,
}

Render_Pass_Action :: struct {
    colors: [MAX_COLOR_ATTACHMENTS]Color_Action,
    depth: Depth_Action,
    stencil: Stencil_Action,
}

Render_Pass_Info :: struct {
    colors: [4]Attachment_Info,
    depth_stencil: Attachment_Info,
}