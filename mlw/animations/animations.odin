package mlw_animations

import "../math"
import "../core"

Frame_Animation :: struct {
    frames: []math.Recti,
}

Float_Animation :: struct {
    values: []f32,
    lerp: bool,
}

Animation :: union {
    Frame_Animation,
}

Animation_Behavior :: enum {
    Once,
    Loop,
    Reverse_Once,
    Reverse_Loop,
}