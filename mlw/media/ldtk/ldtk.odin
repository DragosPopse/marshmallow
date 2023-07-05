package mlw_ldtk

import "../../core"
import "../../math"
import "../../math/grids"
import "../../gpu"
import "../../imdraw"

import "core:path/filepath"
import "core:os"
import "core:encoding/json"

Tile :: struct {
    tex_rect: math.Recti,   
}

Level :: struct {
    name: string,
    background_texture: imdraw.Texture, // imdraw.Texture needs to disappear from the face of the earth
    size_px: math.Vec2f, // size in pixels
}

Layer_Def :: struct {
    grid_size: int,
    identifier: string,
    uid: int,
    variant: union {
        Int_Layer_Def,
    },
}

Int_Layer_Def :: struct {
    
}

Tileset :: struct {
    texture: imdraw.Texture,
    px_size: math.Vec2i,
    tile_grid_size: int,
}

Layer :: struct {
    def: ^Layer_Def,
}

Int_Layer :: struct {
    tileset: ^Tileset,
    int_grid: grids.Rect_Grid(int),
    auto_layer_tiles: grids.Rect_Grid(Tile),
}

World :: struct {
    levels: map[string]Level,
    dir_path: string, // Useful for all the relative paths
}

world_init :: proc(world: ^World, ldtk_file: string, allocator := context.allocator) {
    data, read_success := os.read_entire_file(ldtk_file)
    json_data, err := json.parse(data, json.DEFAULT_SPECIFICATION, false, context.temp_allocator)
    root := json_data.(json.Object)
    
}

