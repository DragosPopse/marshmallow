package mmlow_third_microui

import mu "vendor:microui"
import "../../platform/event"
import "../../math"
import "core:fmt"
import "../../gpu"

mu_ctx: mu.Context

u8_slider :: proc(ctx: ^mu.Context, val: ^u8, lo, hi: u8) -> (res: mu.Result_Set) {
	mu.push_id(ctx, uintptr(val))
	
	@static tmp: mu.Real
	tmp = mu.Real(val^)
	res = mu.slider(ctx, &tmp, mu.Real(lo), mu.Real(hi), 0, "%.0f", {.ALIGN_CENTER})
	val^ = u8(tmp)
	mu.pop_id(ctx)
	return
}

init :: proc() -> ^mu.Context {
    mu.init(&mu_ctx)
    mu_ctx.text_width, mu_ctx.text_height = mu.default_atlas_text_width, mu.default_atlas_text_height
    _vert_buf, _ind_buf = _create_microui_buffers()
    _atlas_texture = _create_atlas_texture()
    _uniforms.modelview = math.Mat4f(1)
    // Todo(Dragos): Make a way to get width and height of the viewport inside gpu
    
    _input_textures.textures[.Fragment][0] = _atlas_texture

    _input_buffers.buffers[0] = _vert_buf
    _input_buffers.index = _ind_buf

    shader_err: Maybe(string)
    if _shader, shader_err = _create_microui_shader(); shader_err != nil {
        fmt.printf("microui SHADER_ERR: %s\n", shader_err.(string))
        return nil
    }
    _pipeline = _create_microui_pipeline(_shader)

    return &mu_ctx
}

process_platform_event :: proc(ctx: ^mu.Context, ev: event.Event) {
    #partial switch ev.type {
        case .Mouse_Move: mu.input_mouse_move(ctx, cast(i32)ev.move.position.x, cast(i32)ev.move.position.y)
        case .Mouse_Wheel: mu.input_mouse_move(ctx, 0, cast(i32)ev.wheel.scroll.y * -30)
        case .Text_Input: mu.input_text(ctx, ev.text.text)

        case .Mouse_Down, .Mouse_Up: {
            b := _button_map[ev.button.button]
            if ev.type == .Mouse_Down do mu.input_mouse_down(ctx, cast(i32)ev.button.position.x, cast(i32)ev.button.position.y, b)
            else if ev.type == .Mouse_Up do mu.input_mouse_up(ctx, cast(i32)ev.button.position.x, cast(i32)ev.button.position.y, b)
        }

        case .Key_Up, .Key_Down: {
            k := _key_map[cast(int)ev.key.key & 0xff]
            if cast(int)k != 0 && ev.type == .Key_Down do mu.input_key_down(ctx, k)
            else if cast(int)k != 0 && ev.type == .Key_Up do mu.input_key_up(ctx, k)
        }
    }
}


apply_microui_pipeline :: #force_inline proc(viewport_width, viewport_height: int) {
    gpu.apply_pipeline(_pipeline)
    _viewport_width, _viewport_height = viewport_width, viewport_height
}

draw :: proc(ctx: ^mu.Context) {
    commands: ^mu.Command
    for variant in mu.next_command_iterator(ctx, &commands) {
        switch cmd in variant {
            case ^mu.Command_Text: {
                _draw_text(cmd.str, cmd.pos, cmd.color)
            }

            case ^mu.Command_Rect: {
                _draw_rect(cmd.rect, cmd.color)
            }

            case ^mu.Command_Icon: {
                _draw_icon(cast(int)cmd.id, cmd.rect, cmd.color)
            }

            case ^mu.Command_Clip: {
                _flush()
                fmt.printf("Clip Command: %v\n", cmd.rect) // TODO(Dragos): Needs gpu implementation
            }

            case ^mu.Command_Jump: {
                unreachable()
            }
        }
    }

    _flush()
}