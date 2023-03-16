package build_samples

import "core:fmt"
import "../odin-build/build"
import "core:os"
import "core:strings"
import "core:path/filepath"
import "core:c/libc"

Target :: struct {
    platform: build.Platform,
    name: string,
    source: string,
    out_dir: string,
}
Project :: build.Project(Target)

CURRENT_PLATFORM :: build.Platform{ODIN_OS, ODIN_ARCH}

add_sample_target :: proc(project: ^Project, name: string, src: string, out_dir: string) {
    build.add_target(project, Target{CURRENT_PLATFORM, name, src, out_dir})
}

add_wasm_target :: proc(project: ^Project, name: string, src: string, out_dir: string) {
    build.add_target(project, Target{build.Platform{.JS, .wasm32}, name, src, out_dir})
}

modes := [][]build.Default_Target_Mode {
    {.Debug, .Release},
}

copy_dll :: proc(config: build.Config) -> int {
    out_dir := filepath.dir(config.out, context.temp_allocator)

    cmd := fmt.tprintf("xcopy /y /i \"%svendor\\sdl2\\SDL2.dll\" \"%s\\SDL2.dll\"", ODIN_ROOT, out_dir)
    return build.syscall(cmd, true)
}

copy_assets :: proc(config: build.Config) -> int {
    out_dir := filepath.dir(config.out, context.temp_allocator)
    src_dir := config.src
    assets_dir := strings.concatenate({src_dir, "/assets"}, context.temp_allocator)
    if os.exists(assets_dir) {
        when ODIN_OS == .Windows {
            cmd := fmt.tprintf("xcopy /y /i /s /e \"%s\\assets\" \"%s\\assets\"", src_dir, out_dir)
        } else {
            cmd := fmt.tprintf("cp -a \"%s/assets\" \"%s/assets\"", src_dir, out_dir)
        }
        
        return build.syscall(cmd, true)
    } else {
        fmt.printf("Couldn't find %s. Ignoring copying assets.\n", assets_dir)
    }

    return 0
}

add_targets :: proc(project: ^Project) {
    // Note(Dragos): Add wildcards for configs. Like "build samp.*". This will mean that we can use "build *" instead of "build all"
    //add_sample_target(project, "samp.gpu.hello_triangle", "samples/gpu/hello_triangle", "out/samples/gpu/hello_triangle")
    //add_sample_target(project, "samp.gpu.hello_sprite", "samples/gpu/hello_sprite", "out/samples/gpu/hello_sprite")
    add_sample_target(project, "samp.gpu.hello_cube", "samples/gpu/hello_cube", "out/samples/gpu/hello_cube")
    add_sample_target(project, "samp.gpu.post_effects", "samples/gpu/post_effects", "out/samples/gpu/post_effects")
    add_sample_target(project, "samp.gpu.instancing", "samples/gpu/instancing", "out/samples/gpu/instancing")
    add_sample_target(project, "samp.planeteer", "samples/planeteer", "out/samples/planeteer")
    add_wasm_target(project, "wasm.planeteer", "samples/planeteer", "out/samples/wasm_planeteer")
    add_sample_target(project, "samp.imdraw.sprites", "samples/imdraw/sprites", "out/samples/imdraw/sprites")
}

configure_target :: proc(project: Project, target: Target) -> (config: build.Config) {
    config = build.config_make()
 
    config.platform = target.platform
    config.collections["shared"] = strings.concatenate({ODIN_ROOT, "shared"})
    exe_ext := "out"
    if target.platform.os == .Windows {
        exe_ext = "exe"
        build.add_post_build_command(&config, "copy-dll", copy_dll)
    } else if target.platform.os == .JS {
        exe_ext = "wasm"
    }
    build.add_post_build_command(&config, "copy-assets", copy_assets)
    when ODIN_DEBUG {
        config.flags += {.Debug}
        config.optimization = .Minimal
    } else {
        config.optimization = .Speed
        config.flags += {.Disable_Assert, .No_Bounds_Check}
    }

   
    config.out = fmt.aprintf("%s/%s.%s", target.out_dir, target.name, exe_ext)
    config.src = target.source
    config.name = target.name
    config.defines["GL_DEBUG"] = true

    return
}


main :: proc() {
    project: build.Project(Target)
    project.configure_target_proc = configure_target
    options := build.build_options_make_from_args(os.args[1:])
    add_targets(&project)
    build.build_project(project, options)
}