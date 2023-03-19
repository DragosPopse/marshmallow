package mmlow_platform_backend_js

import "vendor:wasm/js"
import "../../event"
import "core:container/queue"
import "core:math/linalg"
import "core:fmt"

EVENT_QUEUE_SIZE :: 256

Event_Queue :: struct {
    queue: [EVENT_QUEUE_SIZE]event.Event,
    length: int,
}

_events_backing: [256]event.Event
_events: queue.Queue(event.Event)

event_queue_push :: proc(q: ^Event_Queue, ev: event.Event) {
    q.queue[q.length] = ev
    q.length += 1
}

event_queue_reset :: proc(q: ^Event_Queue) {
    q.length = 0
}

callback_mouse_move :: proc(ev: js.Event) {
    out: event.Event
    out.type = .Mouse_Move
    out.move.delta = linalg.to_int(ev.data.mouse.movement)
    
    // Excuse me what the fuck? Why does this work? What the fuck
    out.move.position.y = cast(int)ev.data.mouse.offset.x
    out.move.position.x = cast(int)ev.mouse.client.y

    //fmt.printf("Mouse Move: %v\n", out.move.position)
    queue.push_back(&_events, out)
}

callback_mouse_up :: proc(ev: js.Event) {
    out: event.Event
    out.type = .Mouse_Up
    // Note(Dragos): Not really correctly implemented
    out.button.button = cast(event.Mouse_Button)ev.mouse.button
    fmt.printf("Mouse Up: %v\n", out.button.button)
    queue.push_back(&_events, out)
}

callback_mouse_down :: proc(ev: js.Event) {
    out: event.Event
    out.type = .Mouse_Down
    // Note(Dragos): Not really correctly implemented
    out.button.button = cast(event.Mouse_Button)ev.mouse.button
    fmt.printf("Mouse Down: %v\n", out.button.button)
    queue.push_back(&_events, out)
}

callback_wheel ::proc(ev: js.Event) {
    out: event.Event
    out.type = .Mouse_Wheel
    out.wheel.scroll = linalg.to_int(ev.scroll.delta)
    queue.push_back(&_events, out)
}



callback_key_up :: proc(ev: js.Event) {
    out: event.Event
    out.type = .Key_Up
    queue.push_back(&_events, out)
}

callback_key_down :: proc(ev: js.Event) {
    out: event.Event
    out.type = .Key_Down
    queue.push_back(&_events, out)
}