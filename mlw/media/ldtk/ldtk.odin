package mlw_ldtk

import "../../core"
import "../../math"
import "../../math/grids"
import "../../gpu"
import "../../imdraw"

import "core:path/filepath"
import "core:os"
import "core:encoding/json"
import "core:strings"
import "core:mem"

Tile :: struct {
    pos: math.Vec2f,
    tex_pos: math.Vec2i,
    index: int,
}

Layer_Def :: struct {
    grid_size: int,
    identifier: string,
    uid: int,
}

Tile_Layer_Def :: struct {
    using base: Layer_Def,
}

Entity_Layer_Def :: struct {
    using base: Layer_Def,
}

Int_Layer_Def :: struct {
    using base: Layer_Def,
}

Any_Layer_Def :: union {
    Int_Layer_Def,
    Tile_Layer_Def,
    Entity_Layer_Def,
}

Tileset :: struct {
    is_loaded: bool,
    identifier: string,
    uid: int,
    path: string,
    texture: imdraw.Texture,
    px_size: math.Vec2i,
    tile_grid_size: int,
}

Int_Layer :: struct {
    def: ^Int_Layer_Def,
    tileset: ^Tileset,
    int_grid: grids.Rect_Grid(int),
    auto_layer_tiles: []Tile,
}

Tile_Layer :: struct {
    def: ^Tile_Layer_Def,
    tileset: ^Tileset,
}

Entity_Layer :: struct {
    def: ^Entity_Layer_Def,
}

Any_Layer :: union {
    Int_Layer,
    Tile_Layer,
    Entity_Layer,
}

Level_Def :: struct {
    identifier: string,
    uid: string,
    path: string,
    px_size: math.Vec2f,
}

Level :: struct {
    def: ^Level_Def,
    world: ^World,
    layers: []Any_Layer,
}

World :: struct {
    levels: map[string]Level_Def,
    layers: map[string]Any_Layer_Def,
    dir_path: string, // all relative paths are relative to this
    tilesets: map[int]Tileset,
}

create_level :: proc(world: ^World, id: string, allocator := context.allocator) -> (level: Level) {
    level_def, level_exists := &world.levels[id]
    assert(level_exists, "Level does not exist")
    level.def = level_def
    level.world = world
    level.layers = make([]Any_Layer, len(world.layers), allocator)

    data, read_success := os.read_entire_file(level_def.path, context.temp_allocator)
    assert(read_success, "Failed to read ldtkl file")

    json_data, err := json.parse(data, json.DEFAULT_SPECIFICATION, false, context.temp_allocator)
    
    root := json_data.(json.Object)

    layers := root["layerInstances"].(json.Array)
    for l, i in layers {
        layer := l.(json.Object)
        cell_count: math.Vec2i
        id := layer["__identifier"].(json.String)
        layer_def := &world.layers[id]
        cell_count.x = cast(int)layer["__cWid"].(json.Float)
        cell_count.y = cast(int)layer["__cHei"].(json.Float)
        cell_size := cast(f32)layer["__gridSize"].(json.Float)
        // TODO: tilesets
        switch var in layer_def {
        case Int_Layer_Def:
            int_layer: Int_Layer
            int_layer.def = &layer_def.(Int_Layer_Def)
            auto_tiles := layer["autoLayerTiles"].(json.Array)
            int_layer.auto_layer_tiles = make([]Tile, len(auto_tiles), allocator)
            for at, tile_i in auto_tiles {
                auto_tile := at.(json.Object)
                px := auto_tile["px"].(json.Array)
                src := auto_tile["src"].(json.Array)
                d := auto_tile["d"].(json.Array)
                tile: Tile
                tile.pos.x = cast(f32)px[0].(json.Float)
                tile.pos.y = cast(f32)px[1].(json.Float)
                tile.tex_pos.x = cast(int)src[0].(json.Float)
                tile.tex_pos.y = cast(int)src[1].(json.Float)
                tile.index = cast(int)d[1].(json.Float)
                int_layer.auto_layer_tiles[tile_i] = tile
                int_layer.tileset = &world.tilesets[cast(int)layer["__tilesetDefUid"].(json.Float)]
            }
            level.layers[i] = int_layer
        
        case Tile_Layer_Def:

        case Entity_Layer_Def:

        }
    }

    return level
}

// Warning: The loader assumes the levels are in separate files
world_init :: proc(world: ^World, ldtk_file: string, allocator := context.allocator) {
    world.dir_path = filepath.dir(ldtk_file, allocator)
    data, read_success := os.read_entire_file(ldtk_file, context.temp_allocator)
    assert(read_success, "Failed to load ldtk file.")
    json_data, err := json.parse(data, json.DEFAULT_SPECIFICATION, false, context.temp_allocator)
    root := json_data.(json.Object)

    defs := root["defs"].(json.Object)

    { // Layer definitions
        layers := defs["layers"].(json.Array)
        for l in layers {
            layer := l.(json.Object)
            layer_def: Layer_Def
            // Common things
            type := layer["__type"].(json.String)
            layer_def.identifier = strings.clone(layer["identifier"].(json.String), allocator)
            layer_def.uid = cast(int)layer["uid"].(json.Float)
            layer_def.grid_size = cast(int)layer["gridSize"].(json.Float)
            //

            switch type {
            case "Tiles":
                tiles_layer: Tile_Layer_Def
                tiles_layer.base = layer_def
                world.layers[tiles_layer.identifier] = tiles_layer

            case "IntGrid":
                int_layer: Int_Layer_Def
                int_layer.base = layer_def
                world.layers[int_layer.identifier] = int_layer

            case "Entities":
                entity_layer: Entity_Layer_Def
                entity_layer.base = layer_def
                world.layers[entity_layer.identifier] = entity_layer
            }
        }
    }

    { // Tileset definitions
        tilesets := defs["tilesets"].(json.Array)
        for t in tilesets {
            ts := t.(json.Object)
            tileset: Tileset
            tileset.is_loaded = false
            rel_path := ts["relPath"].(json.String)
            tileset.path = filepath.join({world.dir_path, rel_path}, allocator)
            tileset.px_size.x = cast(int)ts["pxWid"].(json.Float)
            tileset.px_size.y = cast(int)ts["pxHei"].(json.Float)
            tileset.tile_grid_size = cast(int)ts["tileGridSize"].(json.Float)
            tileset.identifier = strings.clone(ts["identifier"].(json.String))
            tileset.uid = cast(int)ts["uid"].(json.Float)
            world.tilesets[tileset.uid] = tileset
        }
    }

    
    { // Load the data required to lazily load the other levels on demand
        levels := root["levels"].(json.Array)
        for l in levels {
            level := l.(json.Object)
            level_def: Level_Def
            level_def.identifier = strings.clone(level["identifier"].(json.String), allocator)
            level_def.px_size.x = cast(f32)level["pxWid"].(json.Float)
            level_def.px_size.y = cast(f32)level["pxHei"].(json.Float)
            rel_path := level["externalRelPath"].(json.String)
            level_def.path = filepath.join({world.dir_path, rel_path}, allocator)
            world.levels[level_def.identifier] = level_def
        }
    }
}

