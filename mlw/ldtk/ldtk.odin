package mlw_ldtk

import "../core"
import "../math"
import "../math/grids"
import "../gpu"
import "../imdraw"

import "core:path/filepath"
import "core:os"
import "core:encoding/json"

// This has a weird dependency on imdraw.Texture. I would like to remove imdraw.Texture entirely
Level :: struct {
    name: string,
    background: imdraw.Texture,
    size_px: math.Vec2f, // size in pixels
}

Layer :: struct {
    variant: union {
        Entity_Layer,
        Tile_Layer,
    },
}

Tileset :: struct {
    texture: imdraw.Texture,
}

Entity_Layer :: struct {

}

Tile_Layer :: struct {
    
}

World :: struct {
    levels: map[string]Level,
    dir_path: string,
}

load_world_from_path :: proc(path: string, allocator := context.allocator) -> (world: World) {
    
    return world
}