package main

import "../../mlw/math"
import linalg "core:math/linalg"

Mesh :: struct {
    vertices: []math.Vec3f,
    indices: []i32,
    normals: []math.Vec3f,
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
    face.mesh.indices = make([]i32, (face.resolution - 1) * (face.resolution - 1) * 6)
    current_index := 0
    for y in 0..<face.resolution {
        for x in 0..<face.resolution {
            i := y * face.resolution + x
            fx, fy := f32(x), f32(y)
            percent := math.Vec2f{fx, fy} / f32(face.resolution - 1)
            unit_cube_point: math.Vec3f
            unit_cube_point.xyz = face.local_up + (percent.x - 0.5) * 2 * face.axis_a + (percent.y - 0.5) * 2 * face.axis_b
            face.mesh.vertices[i] = unit_cube_point

            if x != face.resolution - 1 && y != face.resolution - 1 {
                face.mesh.indices[current_index] = i32(i)
                face.mesh.indices[current_index + 1] = i32(i + face.resolution + 1)
                face.mesh.indices[current_index + 2] = i32(i + face.resolution)

                face.mesh.indices[current_index + 3] = i32(i)
                face.mesh.indices[current_index + 4] = i32(i + 1)
                face.mesh.indices[current_index + 5] = i32(i + face.resolution + 1)

                current_index += 6
            }
        }
    }
    // TODO(Dragos): Calculate normals
}

delete_terrain_face :: proc(face: Terrain_Face) {
    
}