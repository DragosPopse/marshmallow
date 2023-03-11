package mmlow_platform_event

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

Event_Type :: enum {
    Invalid = 0,
    Mouse_Down, Mouse_Up,
    Mouse_Move,
    Mouse_Wheel,
    Key_Down, Key_Up, Key_Hold,
    Text_Input,
    Quit,
}

Mouse_Button :: enum {
    Left,
    Right,
    Wheel,
}

Common_Event :: struct {
    type: Event_Type,
}


Key_Event :: struct {
    using _: Common_Event,
    key: Key,
}

Text_Input_Event :: struct {
    using _: Common_Event,
    text: string,
}

Mouse_Button_Event :: struct {
    using _: Common_Event,
    position: [2]int,
    button: Mouse_Button,
}

Mouse_Wheel_Event :: struct {
    using _: Common_Event,
    scroll: [2]int,
}

Mouse_Move_Event :: struct {
    using _: Common_Event,
    position: [2]int,
    delta: [2]int,
}

Quit_Event :: struct {
    using _: Common_Event,
}

Event :: struct #raw_union {
    type: Event_Type,
    key: Key_Event,
    button: Mouse_Button_Event,
    move: Mouse_Move_Event,
    wheel: Mouse_Wheel_Event,
    quit: Quit_Event,
    text: Text_Input_Event,
}