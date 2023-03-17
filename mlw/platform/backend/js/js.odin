package mmlow_platform_backend_js

import "../../event"
import "../../../core"
import "core:runtime"

init :: proc(info: core.Platform_Info) {

}

teardown :: proc() {

}

update_window :: proc() {

}

poll_event :: proc() -> (ev: event.Event, ok: bool) {

    return
}

get_backend_window :: proc() -> (window: rawptr) {
    return
}

