package mlw_grids

import "../../math"
import "core:fmt"

/*
    Grid where each cell is a rectangle

*/
Rect_Grid :: struct($Tile: typeid) {
    cell_size: math.Vec2f,
    size: math.Vec2i,
    position: math.Vec2f,
    tiles: []Tile,
}

rect_grid_make_tiles :: proc(grid: ^Rect_Grid($Tile), allocator := context.allocator) {
    assert(grid.size.x != 0 && grid.size.y != 0, "Cannot create tiles with the current size. Did you forget to set it?")
    grid.tiles = make([]Tile, grid.size.x * grid.size.y, allocator)
}

rect_grid_delete_tiles :: proc(grid: ^Rect_Grid($Tile), allocator := context.allocator) {
    delete(grid.tiles, allocator)
}

is_cell_on_rect_grid :: #force_inline proc(grid: Rect_Grid($Tile), cell: math.Vec2i) -> bool {
    return cell.x > 0 && cell.x < grid.size.x && cell.y > 0 && cell.y < grid.size.y
}

rect_grid_set_tile :: proc(grid: ^Rect_Grid($Tile), cell: math.Vec2i, tile: Tile) {
    fmt.assertf(is_cell_on_rect_grid(grid), "Cell [%v, %v] is outside of the grid of size [%v, %v]", cell.x, cell.y, grid.size.x, grid.size.y)
    #no_bounds_check grid.tiles[cell.y * grid.size.x + cell.x] = tile
}

rect_grid_world_to_cell :: proc(grid: Rect_Grid($Tile), world_position: math.Vec2f) -> (cell: math.Vec2i) {
    cell.x = math.floor_to_int((world_position.x - grid.position.x) / grid.cell_size.x)
    cell.y = math.floor_to_int((world_position.y - grid.position.y) / grid.cell_size.y)
    return cell
}

rect_grid_cell_to_world :: proc(grid: Rect_Grid($Tile), cell: math.Vec2i) -> (pos: math.Vec2f) {
    return grid.position + math.to_vec2f(cell) * grid.cell_size
}

rect_grid_index_to_cell :: #force_inline proc(grid: Rect_Grid($Tile), index: int) -> (cell: math.Vec2i) {
    cell.x = index % grid.size.x
    cell.y = index / grid.size.x
    return cell
}

rect_grid_cell_to_index :: #force_inline proc(grid: Rect_Grid($Tile), cell: math.Vec2i) -> (index: int) {
    return cell.y * grid.size.x + cell.x
}

rect_grid_cell_to_tile :: proc(grid: Rect_Grid($Tile), cell: math.Vec2i) -> Tile {
    fmt.assertf(is_cell_on_rect_grid(grid), "Cell [%v, %v] is outside of the grid of size [%v, %v]", cell.x, cell.y, grid.size.x, grid.size.y)
    #no_bounds_check return grid.tiles[cell.y * grid.size.x + cell.x]
}

rect_grid_cell_to_tile_ptr :: proc(grid: ^Rect_Grid($Tile), cell: math.Vec2i) -> ^Tile {
    fmt.assertf(is_cell_on_rect_grid(grid), "Cell [%v, %v] is outside of the grid of size [%v, %v]", cell.x, cell.y, grid.size.x, grid.size.y)
    #no_bounds_check return &grid.tiles[cell.y * grid.size.x + cell.x]
}