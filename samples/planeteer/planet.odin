package main

import "../../mlw/math"
import linalg "core:math/linalg"
import "../../mlw/gpu"
import intr "core:intrinsics"

Mesh :: struct {
    vertices: []math.Vec3f,
    indices: []u32,
    normals: []math.Vec3f,
}

Planet :: struct {
    terrain_faces: [6]Terrain_Face,
}

init_planet :: proc(planet: ^Planet, resolution: int) {
    directions := [6]math.Vec3f{
        {1, 0, 0},
        {-1, 0, 0},
        {0, 1, 0},
        {0, -1, 0},
        {0, 0, 1},
        {0, 0, -1},
    }

    for face, i in &planet.terrain_faces {
        init_terrain_face(&face, resolution, directions[i])
    }
}

construct_planet_mesh :: proc(planet: ^Planet) {
    for face in &planet.terrain_faces {
        construct_terrain_face_mesh(&face)
    }
}

Terrain_Face :: struct {
    mesh: Mesh,
    local_up: math.Vec3f,
    axis_a: math.Vec3f,
    axis_b: math.Vec3f,
    resolution: int,
}

init_terrain_face :: proc(face: ^Terrain_Face, resolution: int, up: math.Vec3f) {
    face.local_up = up
    face.resolution = resolution
    face.axis_a = math.Vec3f{up.y, up.z, up.x}
    face.axis_b = linalg.cross(up, face.axis_a)
}

construct_terrain_face_mesh :: proc(face: ^Terrain_Face) {
    face.mesh.vertices = make([]math.Vec3f, face.resolution * face.resolution)
    face.mesh.indices = make([]u32, (face.resolution - 1) * (face.resolution - 1) * 6)
    current_index := 0
    for y in 0..<face.resolution {
        for x in 0..<face.resolution {
            i := y * face.resolution + x
            fx, fy := f32(x), f32(y)
            percent := math.Vec2f{fx, fy} / f32(face.resolution - 1)
            unit_cube_point: math.Vec3f
            unit_cube_point.xyz = face.local_up + (percent.x - 0.5) * 2 * face.axis_a + (percent.y - 0.5) * 2 * face.axis_b
            unit_cube_point = linalg.normalize(unit_cube_point)
            face.mesh.vertices[i] = unit_cube_point
            
            // Setup triangles
            if x != face.resolution - 1 && y != face.resolution - 1 {
                face.mesh.indices[current_index] = u32(i)
                face.mesh.indices[current_index + 1] = u32(i + face.resolution + 1)
                face.mesh.indices[current_index + 2] = u32(i + face.resolution)

                face.mesh.indices[current_index + 3] = u32(i)
                face.mesh.indices[current_index + 4] = u32(i + 1)
                face.mesh.indices[current_index + 5] = u32(i + face.resolution + 1)

                current_index += 6
            }
        }
    }
    // TODO(Dragos): Calculate normals
}

delete_terrain_face :: proc(face: Terrain_Face) {
    
}

// Note(Dragos): This is currently wrong
merge_planet_meshes :: proc(planet: Planet, allocator := context.allocator) -> (vertices: []math.Vec3f, indices: []u32) {
    context.allocator = allocator
    vertex_list: [dynamic]math.Vec3f
    index_list: [dynamic]u32
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

    return vertex_list[:], index_list[:]
}