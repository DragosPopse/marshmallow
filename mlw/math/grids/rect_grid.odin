package mlw_grids

import "../../math"

Rect_Grid :: struct {
    cell_size: math.Vec2f,
    size: math.Vec2i,
    position: math.Vec2f,
}

rect_grid_init :: proc(grid: ^Rect_Grid, position: math.Vec2f, size: math.Vec2i, cell_size: math.Vec2f) {
    grid.position = position
    grid.size = size
    grid.cell_size = cell_size
}

rect_grid_cell_from_world_position :: proc(grid: Rect_Grid, world_position: math.Vec2f) -> (cell: math.Vec2i) {
    cell.x = math.floor_to_int((world_position.x - grid.position.x) / grid.cell_size.x)
    cell.y = math.floor_to_int((world_position.y - grid.position.y) / grid.cell_size.y)
    return cell
}


