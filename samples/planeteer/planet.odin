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
    settings: Planet_Settings,
}

init_planet :: proc(planet: ^Planet) {
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
}

Terrain_Face :: struct {
    mesh: Mesh,
    local_up: math.Vec3f,
    axis_a: math.Vec3f,
    axis_b: math.Vec3f,
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
    current_index := 0
    for y in 0..<settings.resolution {
        for x in 0..<settings.resolution {
            i := y * settings.resolution + x
            fx, fy := f32(x), f32(y)
            percent := math.Vec2f{fx, fy} / f32(settings.resolution - 1)
            unit_cube_point: math.Vec3f
            unit_cube_point.xyz = face.local_up + (percent.x - 0.5) * 2 * face.axis_a + (percent.y - 0.5) * 2 * face.axis_b
            unit_cube_point = linalg.normalize(unit_cube_point)
            elevation := f32(0)
            for noise_layer in settings.noise_layers do if noise_layer.enabled {
                elevation += evaluate_noise(noise_layer.noise, unit_cube_point)
            }
            
            unit_cube_point = unit_cube_point * settings.radius * f32(1 + elevation)
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
    // TODO(Dragos): Calculate normals
   
}

destroy_terrain_face :: proc(face: Terrain_Face, allocator := context.allocator) {
    context.allocator = allocator
    using face
    delete(mesh.indices)
    delete(mesh.vertices)
    delete(mesh.normals)
}

// Note(Dragos): This is currently wrong
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