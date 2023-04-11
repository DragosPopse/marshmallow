package main

import "../../mlw/math"
import linalg "core:math/linalg"
import "../../mlw/gpu"
import "core:fmt"
import "core:thread"


Vertex :: struct {
    pos: [3]f32,
    normal: [3]f32,
}

Mesh :: struct {
    vertices: []Vertex,
    indices: []u32,
    normals: []math.Vec3f,
}

Planet :: struct {
    terrain_faces: [6]Terrain_Face,
    _elevation_min, _elevation_max: f32,
    settings: Planet_Settings,
}

Planet_Vert_Uniforms :: struct {
    model, view, projection: math.Mat4f,
}

Planet_Frag_Uniforms :: struct {
    ElevationMinMax: [2]f32,
}

init_planet :: proc(planet: ^Planet, settings: Planet_Settings) {
    planet.settings = settings
    directions := [6]math.Vec3f{
        {1, 0, 0},
        {-1, 0, 0},
        {0, 1, 0},
        {0, -1, 0},
        {0, 0, 1},
        {0, 0, -1},
    }

    for face, i in &planet.terrain_faces {
        init_terrain_face(&face, directions[i])
    }
}

// MVC shouldn't really be here, but it's fine for now
update_planet_uniforms :: proc(planet: Planet, model, view, projection: math.Mat4f) {
    vert_uniforms: Planet_Vert_Uniforms
    frag_uniforms: Planet_Frag_Uniforms

    vert_uniforms.model = model
    vert_uniforms.view = view
    vert_uniforms.projection = projection

    frag_uniforms.ElevationMinMax = {planet._elevation_min, planet._elevation_max}
    gpu.apply_uniforms_raw(.Vertex, 0, &vert_uniforms, size_of(Planet_Vert_Uniforms))
    gpu.apply_uniforms_raw(.Fragment, 0, &frag_uniforms, size_of(Planet_Frag_Uniforms))
}


create_planet_shader :: proc() -> (shader: gpu.Shader, err: Maybe(string)) {
    vert_info: gpu.Shader_Stage_Info
    vert: gpu.Shader_Stage
    frag_info: gpu.Shader_Stage_Info
    frag: gpu.Shader_Stage
   
    when gpu.BACKEND == .glcore3 {
        vert_info.src = #load("glcore3/planet.vert.glsl", string)
        frag_info.src = #load("glcore3/planet.frag.glsl", string)
    } else when gpu.BACKEND == .webgl2 {
        vert_info.src = #load("webgl2/planet.vert.glsl", string)
        frag_info.src = #load("webgl2/planet.frag.glsl", string)
    }

    vert_info.type = .Vertex

    vert_info.uniform_blocks[0].size = size_of(Planet_Vert_Uniforms)
    vert_info.uniform_blocks[0].uniforms[0].name = "model"
    vert_info.uniform_blocks[0].uniforms[0].type = .mat4f32
    vert_info.uniform_blocks[0].uniforms[1].name = "view"
    vert_info.uniform_blocks[0].uniforms[1].type = .mat4f32
    vert_info.uniform_blocks[0].uniforms[2].name = "projection"
    vert_info.uniform_blocks[0].uniforms[2].type = .mat4f32

    if vert, err = gpu.create_shader_stage(vert_info); err != nil {
        return 0, err
    }
    defer gpu.destroy_shader_stage(vert)

  

    frag_info.type = .Fragment

    // Should this be a different uniform block? Idk
    frag_info.uniform_blocks[0].size = size_of(Planet_Frag_Uniforms)
    frag_info.uniform_blocks[0].uniforms[0].name = "ElevationMinMax"
    frag_info.uniform_blocks[0].uniforms[0].type = .vec2f32
    frag_info.textures[0].name = "Gradient"
    frag_info.textures[0].type = .Texture2D

    if frag, err = gpu.create_shader_stage(frag_info); err != nil {
        return 0, err
    }
    defer gpu.destroy_shader_stage(frag)

    shader_info: gpu.Shader_Info
    shader_info.stages[.Vertex] = vert
    shader_info.stages[.Fragment] = frag

    if shader, err = gpu.create_shader(shader_info, false); err != nil {
        return 0, err
    }

    return shader, nil
}

destroy_planet :: proc(planet: Planet, allocator := context.allocator) {
    context.allocator = allocator

    for face in planet.terrain_faces {
        destroy_terrain_face(face)
    }
}

construct_planet_mesh_single_threaded :: proc(planet: ^Planet, settings: Planet_Settings, allocator := context.allocator) {
    planet.settings = settings
    for face in &planet.terrain_faces {
        construct_terrain_face_mesh(&face, settings, allocator)
    }
    planet._elevation_max = min(f32)
    planet._elevation_min = max(f32)
    for face in planet.terrain_faces {
        if face._elevation_max > planet._elevation_max do planet._elevation_max = face._elevation_max
        if face._elevation_min < planet._elevation_min do planet._elevation_min = face._elevation_min
    }
}

construct_planet_mesh :: proc(planet: ^Planet, settings: Planet_Settings, pool: ^thread.Pool, allocator := context.allocator) {
    Task_Data :: struct {
        face: ^Terrain_Face,
        settings: Planet_Settings,
    }

    task :: proc(task: thread.Task) {
        data := cast(^Task_Data)task.data
        construct_terrain_face_mesh(data.face, data.settings, task.allocator)
    }

    for face in &planet.terrain_faces {
        data := new(Task_Data, context.temp_allocator)
        data.face = &face
        data.settings = settings
        thread.pool_add_task(pool, allocator, task, data)
    }
    
    for !thread.pool_is_empty(pool) {
        for _ in thread.pool_pop_done(pool) {

        }
    }

    planet._elevation_max = min(f32)
    planet._elevation_min = max(f32)
    for face in planet.terrain_faces {
        if face._elevation_max > planet._elevation_max do planet._elevation_max = face._elevation_max
        if face._elevation_min < planet._elevation_min do planet._elevation_min = face._elevation_min
    }
}

Terrain_Face :: struct {
    mesh: Mesh,
    local_up: math.Vec3f,
    axis_a: math.Vec3f,
    axis_b: math.Vec3f,
    _elevation_min, _elevation_max: f32,
}

init_terrain_face :: proc(face: ^Terrain_Face, up: math.Vec3f) {
    face.local_up = up
    face.axis_a = math.Vec3f{up.y, up.z, up.x}
    face.axis_b = linalg.cross(up, face.axis_a)
}

construct_terrain_face_mesh :: proc(face: ^Terrain_Face, settings: Planet_Settings, allocator := context.allocator) {
    using settings
    context.allocator = allocator
    face.mesh.vertices = make([]Vertex, settings.resolution * settings.resolution)
    face.mesh.indices = make([]u32, (settings.resolution - 1) * (settings.resolution - 1) * 6)
    face._elevation_min = max(f32)
    face._elevation_max = min(f32)
    current_index := 0
    for y in 0..<settings.resolution {
        for x in 0..<settings.resolution {
            i := y * settings.resolution + x
            fx, fy := f32(x), f32(y)
            percent := math.Vec2f{fx, fy} / f32(settings.resolution - 1)
            unit_cube_point: math.Vec3f
            unit_cube_point.xyz = face.local_up + (percent.x - 0.5) * 2 * face.axis_a + (percent.y - 0.5) * 2 * face.axis_b
            unit_cube_point = linalg.normalize(unit_cube_point)

            first_layer_value := f32(0)
            elevation := f32(0)
            if settings.noise_layers_count > 0 {
                first_layer_value = evaluate_noise(settings.noise_layers[0].noise, unit_cube_point)
                if settings.noise_layers[0].enabled {
                    elevation += first_layer_value
                }
            }
        
            for i in 1..<settings.noise_layers_count do if settings.noise_layers[i].enabled {
                mask := first_layer_value if settings.noise_layers[i].use_first_layer_as_mask else f32(1)

                elevation += evaluate_noise(settings.noise_layers[i].noise, unit_cube_point) * mask
            }
            
            elevation = settings.radius * f32(1 + elevation)
            face._elevation_min, face._elevation_max = math.minmax(elevation, face._elevation_min, face._elevation_max)
            unit_cube_point = unit_cube_point * elevation

            face.mesh.vertices[i].pos = unit_cube_point.xyz
            
            // Setup triangles
            if x != settings.resolution - 1 && y != settings.resolution - 1 {
                face.mesh.indices[current_index] = u32(i)
                face.mesh.indices[current_index + 1] = u32(i + settings.resolution + 1)
                face.mesh.indices[current_index + 2] = u32(i + settings.resolution)

                face.mesh.indices[current_index + 3] = u32(i)
                face.mesh.indices[current_index + 4] = u32(i + 1)
                face.mesh.indices[current_index + 5] = u32(i + settings.resolution + 1)

                current_index += 6
            }
        }
    }   
}

destroy_terrain_face :: proc(face: Terrain_Face, allocator := context.allocator) {
    context.allocator = allocator
    using face
    delete(mesh.indices)
    delete(mesh.vertices)
    delete(mesh.normals)
}

merge_planet_meshes :: proc(planet: Planet, allocator := context.allocator) -> (vertices: []Vertex, indices: []u32) {
    context.allocator = allocator
    vertex_list: [dynamic]Vertex
    //resize_dynamic_array(&vertex_list, planet.settings.resolution * planet.settings.resolution * 6)
    index_list: [dynamic]u32
    //resize_dynamic_array(&index_list, (planet.settings.resolution - 1) * (planet.settings.resolution - 1) * 6 * 6)
    current_index := 0
    for face, i in planet.terrain_faces {
        last_vertex_len := cast(u32)len(vertex_list)
        append(&vertex_list, ..face.mesh.vertices)
        append(&index_list, ..face.mesh.indices)
        for idx := current_index; idx < len(index_list); idx += 1 {
            index_list[idx] += last_vertex_len
        }
        current_index = len(index_list)
    }

    // Normal Calculations. Not smooth yet
    for i := 0; i < len(index_list); i += 3 {
        v1 := &vertex_list[index_list[i + 0]]
        v2 := &vertex_list[index_list[i + 1]]
        v3 := &vertex_list[index_list[i + 2]]
        edge1 := v2.pos - v1.pos
        edge2 := v3.pos - v1.pos
        normal := linalg.cross(edge1, edge2)
        
        normal = linalg.normalize(normal)
        v1.normal, v2.normal, v3.normal = normal, normal, normal
        //fmt.printf("[%v, %v, %v]: %.6f\n", v1.pos, v2.pos, v3.pos, normal)
    }

    return vertex_list[:], index_list[:]
}