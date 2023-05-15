package mlw_jobs

import "core:sync"
import "core:thread"
import "core:runtime"

// Make it dumb at first. Only 1 group execution at a time. Expand later

// This API will be changed once more features are added

State :: struct {
    pool: thread.Pool,
    in_group: bool,
    allocator: runtime.Allocator,
}

state: State

init :: proc(allocator: runtime.Allocator, thread_count: int) {
    state.allocator = allocator
    thread.pool_init(&state.pool, state.allocator, thread_count)
    thread.pool_start(&state.pool)
}

teardown :: proc() {
    thread.pool_destroy(&state.pool)
}

group_start :: proc() {
    assert(!state.in_group, "Cannot start a new group while another one is being configured")
    state.in_group = true
}

add :: proc(task: thread.Task_Proc, userdata: rawptr, user_index: int, allocator: runtime.Allocator) {
    assert(state.in_group, "A group must be currently in configuration. Call jobs.group_start")
    thread.pool_add_task(&state.pool, allocator, task, userdata, user_index)
}

group_end_join :: proc() {
    assert(state.in_group, "A group must be currently in configuration in order to join. Call jobs.group_start")
    for !thread.pool_is_empty(&state.pool) {
        for task in thread.pool_pop_done(&state.pool) {
            
        }
    }
    state.in_group = false
}

@(deferred_none = group_end_join) 
join_group :: proc() {
    group_start()
}