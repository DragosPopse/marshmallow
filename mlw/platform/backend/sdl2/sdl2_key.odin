package highland_platform_backend_sdl2

import sdl "vendor:sdl2"
import "../../../core"

_SCANCODE_TO_KEY := #partial #sparse [sdl.Scancode]core.Key {
    .A = core.Key.A,
	.B = core.Key.B,
	.C = core.Key.C,
	.D = core.Key.D,
	.E = core.Key.E,
	.F = core.Key.F,
	.G = core.Key.G,
	.H = core.Key.H,
	.I = core.Key.I,
	.J = core.Key.J,
	.K = core.Key.K,
	.L = core.Key.L,
	.M = core.Key.M,
	.N = core.Key.N,
	.O = core.Key.O,
	.P = core.Key.P,
	.Q = core.Key.Q,
	.R = core.Key.R,
	.S = core.Key.S,
	.T = core.Key.T,
	.U = core.Key.U,
	.V = core.Key.V,
	.W = core.Key.W,
	.X = core.Key.X,
	.Y = core.Key.Y,
	.Z = core.Key.Z,

    .NUM1 = core.Key.Num1,
    .NUM2 = core.Key.Num2,
    .NUM3 = core.Key.Num3,
    .NUM4 = core.Key.Num4,
    .NUM5 = core.Key.Num5,
    .NUM6 = core.Key.Num6,
    .NUM7 = core.Key.Num7,
    .NUM8 = core.Key.Num8,
    .NUM9 = core.Key.Num9,
    .NUM0 = core.Key.Num0,

    .RETURN = core.Key.Return,
    .ESCAPE = core.Key.Escape,
    .BACKSPACE = core.Key.Backspace,
    .TAB = core.Key.Tab,
    .SPACE = core.Key.Space,

    .MINUS        = core.Key.Minus,
	.EQUALS       = core.Key.Equals,
	.LEFTBRACKET  = core.Key.LBracket,
	.RIGHTBRACKET = core.Key.RBracket,
	.BACKSLASH    = core.Key.Backslash,
	.SEMICOLON    = core.Key.Semicolon,
	.APOSTROPHE   = core.Key.Apostrophe,
	.GRAVE        = core.Key.Grave,
	.COMMA        = core.Key.Comma,
	.PERIOD       = core.Key.Period,
	.SLASH        = core.Key.Slash,

	.CAPSLOCK = core.Key.Capslock,

	.F1 = core.Key.F1,
	.F2 = core.Key.F2,
	.F3 = core.Key.F3,
	.F4 = core.Key.F4,
	.F5 = core.Key.F5,
	.F6 = core.Key.F6,
	.F7 = core.Key.F7,
	.F8 = core.Key.F8,
	.F9 = core.Key.F9,
	.F10 = core.Key.F10,
	.F11 = core.Key.F11,
	.F12 = core.Key.F12,
	
	.RIGHT = core.Key.Right,
	.LEFT = core.Key.Left,
	.DOWN = core.Key.Down,
	.UP = core.Key.Up,

    .LCTRL = core.Key.LControl,
    .LSHIFT = core.Key.LShift,
    .LALT = core.Key.LAlt,
    .LGUI = core.Key.LSystem,
    .RCTRL = core.Key.RControl,
    .RSHIFT = core.Key.RShift,
    .RALT = core.Key.RAlt,
    .RGUI = core.Key.RSystem,
}


_KEY_TO_SCANCODE := #partial #sparse [core.Key]sdl.Scancode {
    .Unknown = sdl.Scancode.UNKNOWN,

    .A = sdl.Scancode.A,
	.B = sdl.Scancode.B,
	.C = sdl.Scancode.C,
	.D = sdl.Scancode.D,
	.E = sdl.Scancode.E,
	.F = sdl.Scancode.F,
	.G = sdl.Scancode.G,
	.H = sdl.Scancode.H,
	.I = sdl.Scancode.I,
	.J = sdl.Scancode.J,
	.K = sdl.Scancode.K,
	.L = sdl.Scancode.L,
	.M = sdl.Scancode.M,
	.N = sdl.Scancode.N,
	.O = sdl.Scancode.O,
	.P = sdl.Scancode.P,
	.Q = sdl.Scancode.Q,
	.R = sdl.Scancode.R,
	.S = sdl.Scancode.S,
	.T = sdl.Scancode.T,
	.U = sdl.Scancode.U,
	.V = sdl.Scancode.V,
	.W = sdl.Scancode.W,
	.X = sdl.Scancode.X,
	.Y = sdl.Scancode.Y,
	.Z = sdl.Scancode.Z,

    .Num1 = sdl.Scancode.NUM1,
    .Num2 = sdl.Scancode.NUM2,
    .Num3 = sdl.Scancode.NUM3,
    .Num4 = sdl.Scancode.NUM4,
    .Num5 = sdl.Scancode.NUM5,
    .Num6 = sdl.Scancode.NUM6,
    .Num7 = sdl.Scancode.NUM7,
    .Num8 = sdl.Scancode.NUM8,
    .Num9 = sdl.Scancode.NUM9,
    .Num0 = sdl.Scancode.NUM0,

    .Return = sdl.Scancode.RETURN,
    .Escape = sdl.Scancode.ESCAPE,
    .Backspace = sdl.Scancode.BACKSPACE,
    .Tab = sdl.Scancode.TAB,
    .Space = sdl.Scancode.SPACE,

    .Minus        = sdl.Scancode.MINUS,
	.Equals       = sdl.Scancode.EQUALS,
	.LBracket  = sdl.Scancode.LEFTBRACKET,
	.RBracket = sdl.Scancode.RIGHTBRACKET,
	.Backslash    = sdl.Scancode.BACKSLASH,
	.Semicolon    = sdl.Scancode.SEMICOLON,
	.Apostrophe   = sdl.Scancode.APOSTROPHE,
	.Grave        = sdl.Scancode.GRAVE,
	.Comma        = sdl.Scancode.COMMA,
	.Period       = sdl.Scancode.PERIOD,
	.Slash        = sdl.Scancode.SLASH,

	.Capslock = sdl.Scancode.CAPSLOCK,

	.F1 = sdl.Scancode.F1,
	.F2 = sdl.Scancode.F2,
	.F3 = sdl.Scancode.F3,
	.F4 = sdl.Scancode.F4,
	.F5 = sdl.Scancode.F5,
	.F6 = sdl.Scancode.F6,
	.F7 = sdl.Scancode.F7,
	.F8 = sdl.Scancode.F8,
	.F9 = sdl.Scancode.F9,
	.F10 = sdl.Scancode.F10,
	.F11 = sdl.Scancode.F11,
	.F12 = sdl.Scancode.F12,
	
	.Right = sdl.Scancode.RIGHT,
	.Left = sdl.Scancode.LEFT,
	.Down = sdl.Scancode.DOWN,
	.Up = sdl.Scancode.UP,

    .LControl = sdl.Scancode.LCTRL,
    .LShift = sdl.Scancode.LSHIFT,
    .LAlt = sdl.Scancode.LALT,
    .LSystem = sdl.Scancode.LGUI,
    .RControl = sdl.Scancode.RCTRL,
    .RShift = sdl.Scancode.RSHIFT,
    .RAlt = sdl.Scancode.RALT,
    .RSystem = sdl.Scancode.RGUI,
}