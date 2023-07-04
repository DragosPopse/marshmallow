package main

import "core:fmt"
import "../../mlw/core"
import "../../mlw/gpu"
import "../../mlw/platform"
import "../../mlw/imdraw"
import "../../mlw/platform/event"
import "../../mlw/math"
import cams "../../mlw/math/camera"


pass_action: gpu.Pass_Action
WIDTH :: 800
HEIGHT :: 600
camera: cams.Camera2D
player: Player
tile: Tile
gravity: f32 = 9.8 * 50
jump_speed: f32 = 400

Player :: struct {
    using rect: math.Rectf,
    tex_rect: math.Recti,
    tex: imdraw.Texture,
    origin: math.Vec2f,
    velocity: math.Vec2f,
    acceleration: math.Vec2f,
}

Tile :: struct {
    using rect: math.Rectf,
    color: math.Color4f,
    origin: math.Vec2f,
}

player_on_event :: proc(player: ^Player, ev: event.Event) {
    #partial switch ev.type {
    case .Key_Down: 
        if ev.key.key == .W {
            player.velocity.y = -jump_speed
        }
    }
}

player_update :: proc(using player: ^Player, dt: f32) {
    velocity += acceleration * dt
    velocity += {0, gravity} * dt
    pos += velocity * dt
}

main :: proc() {
    defer platform.start()
    platform_info: platform.Init_Info
    platform_info.graphics = gpu.default_graphics_info()
    platform_info.step = tick
    platform_info.window.size = {WIDTH, HEIGHT}
    platform_info.window.title = "PlatFormers"
    //platform_info.graphics.vsync = true
    pass_action = gpu.default_pass_action()
    platform.init(platform_info)
    gpu.init()
    imdraw.init()
    
    player.tex = imdraw.create_texture_from_file("./assets/world.png")
    player.tex_rect = {{2, 132}, {12, 12}}
    player.pos = {0, 0}
    player.size = math.to_vec2f(player.tex_rect.size) * 4
    player.origin = {0.5, 0.5}

    camera.origin = {0.5, 0.5}
    camera.size = {WIDTH, HEIGHT}

    tile.pos = {0, 100}
    tile.size = math.to_vec2f(player.tex_rect.size) * 4
    tile.origin = {0.5, 0.5}
    tile.color = math.BLUE_4f
}

tick :: proc(dt: f32) {
    for ev in platform.poll_event() {
        player_on_event(&player, ev)
        #partial switch ev.type {
        case .Quit: 
            platform.quit()
        }
    }

    player_update(&player, dt)

    player_rect := math.rect_align_with_origin(player.rect, player.origin)
    box_rect := math.rect_align_with_origin(tile.rect, tile.origin)

    if penetration := math.solve_collision(player_rect, box_rect); penetration != nil {
        fmt.printf("Velocity: %v\n", player.velocity)
        fmt.printf("Penetration: %v\n", penetration.?)
        player.rect.pos -= penetration.?
        player.velocity.y = 0
    }
   

    gpu.begin_default_pass(pass_action, WIDTH, HEIGHT)

    imdraw.begin()
    imdraw.apply_camera(camera)

    imdraw.sprite(player.tex, player.rect, player.origin, player.tex_rect, math.Rad(0))
    imdraw.quad(tile.rect, tile.origin, math.Rad(0), tile.color)
    imdraw.end()

    gpu.end_pass()

    platform.update_window()
    free_all(context.temp_allocator)
}
