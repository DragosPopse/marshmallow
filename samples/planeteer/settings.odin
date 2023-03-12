package main

import "core:fmt"
import "core:mem"
import "../../mlw/core"
import "../../mlw/gpu"
import "../../mlw/image"
import "../../mlw/math"
import "../../mlw/platform"
import linalg "core:math/linalg"
import "core:slice"
import mu "vendor:microui"
import mu_mlw "../../mlw/third/microui"
import "../../mlw/platform/event"
import cnoise "core:math/noise"

Graphics_Settings :: struct {
	wireframe: bool,
}

Planet_Settings :: struct {
	radius: f32,
	color: math.Colorb,
	resolution: int,
	noise: Noise,
}

Settings :: struct {
	graphics: Graphics_Settings,
	planet: Planet_Settings,
}

Frame_Info :: struct {
	frame_time: f32,
	gen_time: f32,
	buffer_update_time: f32,
}

MAX_RESOLUTION :: 100
VB_SIZE :: 6 * MAX_RESOLUTION * MAX_RESOLUTION * size_of(math.Vec3f) // This will be changed when adding colors
IB_SIZE :: 6 * (MAX_RESOLUTION - 1) * (MAX_RESOLUTION - 1) * 6 * size_of(u32)

default_planet_settings :: proc() -> (settings: Planet_Settings) {
	settings.radius = 1
	settings.resolution = 16
	settings.noise = default_noise()
	return settings
}

settings_window :: proc(ctx: ^mu.Context, settings: ^Settings, frame: Frame_Info) -> (graphics_changed: bool, planet_changed: bool) {
    opts := mu.Options{.NO_CLOSE}
    if mu.window(ctx, "Planeteer", {0, 0, 300, 450}, opts) {
		if .ACTIVE in mu.header(ctx, "Performance") {
			win := mu.get_current_container(ctx)
			CONV :: 1000
			TIME_FMT :: "%.0f ms"
			mu.layout_row(ctx, {120, 120}, 0)
			mu.label(ctx, "Frame Time:")
			mu.label(ctx, fmt.tprintf(TIME_FMT, frame.frame_time * CONV))
			mu.label(ctx, "Generation Time:")
			mu.label(ctx, fmt.tprintf(TIME_FMT, frame.gen_time * CONV))
			mu.label(ctx, "Buffer Update Time:")
			mu.label(ctx, fmt.tprintf(TIME_FMT, frame.buffer_update_time * CONV))
		}

		if .ACTIVE in mu.header(ctx, "Render Settings") {
			mu.layout_row(ctx, {120, 120}, 0)
			if .CHANGE in mu.checkbox(ctx, "Wireframe", &settings.graphics.wireframe)  {
                graphics_changed = true
            }
		}

		if .ACTIVE in mu.header(ctx, "Planet Settings") {
			mu.layout_row(ctx, {120, 120}, 0)
			mu.label(ctx, "Radius:")
			if .CHANGE in mu.slider(ctx, &settings.planet.radius, 1, 6, 0.1)  {
                planet_changed = true
            }

			mu.label(ctx, "Resolution:")
			resolution := cast(f32)settings.planet.resolution
			if .CHANGE in mu.slider(ctx, &resolution, 2, MAX_RESOLUTION, 1, "%.0f")  {
                planet_changed = true
				settings.planet.resolution = cast(int)resolution
            }

			mu.label(ctx, "Seed:")
			seed := cast(f32)settings.planet.noise.seed
			if .CHANGE in mu.slider(ctx, &seed, 1, 10000, 1, "%.0f")  {
                planet_changed = true
				settings.planet.noise.seed = cast(int)seed
            }

			mu.label(ctx, "Strength:")
			if .CHANGE in mu.slider(ctx, &settings.planet.noise.strength, 0, 5, 0.01)  {
                planet_changed = true
            }

			mu.label(ctx, "Base Roughness:")
			if .CHANGE in mu.slider(ctx, &settings.planet.noise.base_roughness, 0, 5, 0.01)  {
                planet_changed = true
            }

			mu.label(ctx, "Roughness:")
			if .CHANGE in mu.slider(ctx, &settings.planet.noise.roughness, 0, 5, 0.01)  {
                planet_changed = true
            }

			mu.label(ctx, "Persistence:")
			if .CHANGE in mu.slider(ctx, &settings.planet.noise.persistence, 0, 1, 0.01)  {
                planet_changed = true
            }

			mu.label(ctx, "Min Value:")
			if .CHANGE in mu.slider(ctx, &settings.planet.noise.min_value, 0, 5, 0.01)  {
                planet_changed = true
            }

			mu.label(ctx, "Layers:")
			layers := cast(f32)settings.planet.noise.layers_count
			if .CHANGE in mu.slider(ctx, &layers, 1, 5, 1, "%.0f")  {
                planet_changed = true
				settings.planet.noise.layers_count = cast(int)layers
            }
		}
	}

	return
}