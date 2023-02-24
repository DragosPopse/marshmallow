package mmlow_core

import "../math"

Render_Pass :: distinct u32

MAX_COLOR_ATTACHMENTS :: 4
DEFAULT_CLEAR_COLOR :: math.fBLACK
DEFAULT_CLEAR_DEPTH :: 1
DEFAULT_CLEAR_STENCIL :: 0

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

default_pass_action :: proc() -> (action: Render_Pass_Action) {
    for color in &action.colors {
        color.value = DEFAULT_CLEAR_COLOR
    }
    action.depth.value = DEFAULT_CLEAR_DEPTH
    action.stencil.value = DEFAULT_CLEAR_STENCIL
    return action
}