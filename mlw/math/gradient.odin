package mlw_math

import "core:math/linalg"
import "core:fmt"
import cmath "core:math"
import "core:math/rand"
import "core:intrinsics"

Gradient_Color_Key :: struct($Color_Type: typeid) {
    color: Color_Type,
    time: f32,
}

Gradient :: struct($Color_Type: typeid) where intrinsics.type_is_array(Color_Type) {
    color_keys: []Gradient_Color_Key(Color_Type),
}

Gradient4f :: Gradient(Color4f)
Gradient4f_Color_Key :: Gradient_Color_Key(Color4f)

gradient_eval_gradient :: proc(gradient: Gradient($Color_Type), time: f32) -> (result: Color_Type) {
    if len(gradient.color_keys) == 0 do return Color_Type{}
    if len(gradient.color_keys) == 1 do return gradient.color_keys[0].color

    i: int
    for i = 1; i < len(gradient.color_keys) - 1; i += 1 {
        if time < gradient.color_keys[i].time do break
    }

    a := gradient.color_keys[i - 1]
    b := gradient.color_keys[i]
    dt := (time - a.time) / (b.time - a.time)

    // Convert the byte color to float for easier computations
    fa := array_cast(a.color, f32)
    fb := array_cast(b.color, f32)

    return array_cast(fa + (fb - fa) * dt, type_of(result[0]))
}

// Todo(Dragos): Some damn consistency in naming would be nice
gradient_eval :: proc {
    gradient_eval_gradient,
}

/*
// Todo(Dragos): make this work for any type of color

Gradient_Color_Key :: struct {
    color: Color3b,
    time: f32,
}

Gradient :: struct {
    color_keys: []Gradient_Color_Key,
}

gradient_evaluate_from_gradient :: proc(gradient: Gradient, time: f32) -> (result: Color3b) {
    if len(gradient.color_keys) == 0 do return Color3b{}
    if len(gradient.color_keys) == 1 do return gradient.color_keys[0].color

    i: int
    for i = 1; i < len(gradient.color_keys) - 1; i += 1 {
        if time < gradient.color_keys[i].time do break
    }

    a := gradient.color_keys[i - 1]
    b := gradient.color_keys[i]
    dt := (time - a.time) / (b.time - a.time)

    // Convert the byte color to float for easier computations
    fa := to_color3f(a.color)
    fb := to_color3f(b.color)

    return to_color3b(fa.rgb + (fb.rgb - fa.rgb) * dt)
}

// Todo(Dragos): Move this to eval proc group
// Todo(Dragos): Make some color distributions too...
gradient_evaluate :: proc {
    gradient_evaluate_from_gradient,
}

*/