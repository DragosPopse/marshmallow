package mmlow_core

Key :: enum {
    Unknown = 0,

	A,
	B,
	C,
	D,
	E,
	F,
	G,
	H,
	I,
	J,
	K,
	L,
	M,
	N,
	O,
	P,
	Q,
	R,
	S,
	T,
	U,
	V,
	W,
	X,
	Y,
	Z,

	Num1,
	Num2,
	Num3,
	Num4,
	Num5,
	Num6,
	Num7,
	Num8,
	Num9,
	Num0,

    F1,
	F2,
	F3,
	F4,
	F5,
	F6,
	F7,
	F8,
	F9,
	F10,
	F11,
	F12,

	Return,
	Escape,
	Backspace,
	Tab,
	Space,

	Minus,
	Equals,
	LBracket,
	RBracket,
	Backslash,
	Semicolon,
	Apostrophe,
	Grave,
	Comma,
	Period,
	Slash,

	Capslock,

	Right,
	Left,
	Down,
	Up,

	LControl,
	LShift,
	LAlt,
	LSystem,
	RControl,
	RShift,
	RAlt,
	RSystem,
}

Mouse_Button :: enum {
    Left,
    Right,
    Wheel,
}

Event_Base :: struct {

}

Key_Event_Action :: enum {
    Down,
    Up,
    Hold,
}

Key_Event :: struct {
    using _: Event_Base,
    action: Key_Event_Action,
    key: Key,
}

Mouse_Event_Base :: struct {
    using _: Event_Base,
    position: [2]int,
}

Mouse_Button_Event :: struct {
    using _: Mouse_Event_Base,
    button: Mouse_Button,
}

Mouse_Wheel_Event :: struct {
    using _: Mouse_Event_Base,
    scroll: [2]int,
}

Quit_Event :: struct {
    
}

Event :: union {
    Key_Event,
    Mouse_Button_Event,
    Mouse_Wheel_Event,
    Quit_Event,
}