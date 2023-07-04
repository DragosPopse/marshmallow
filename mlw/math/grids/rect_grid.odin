package mlw_grids

import "../../math"

Rect_Grid :: struct($Cell_Type: typeid) {
    cell_size: math.Vec2f,
    size: math.Vec2i,
    position: math.Vec2f,
    cells: []Cell_Type,
}

Rect_Cell_Relative_Position :: enum {
    Top_Left,
    Top_Center,
    Top_Right,
    Center_Left,
    Center_Center,
    Center_Right,
    Bottom_Left,
    Bottom_Center,
    Bottom_Right,
}

rect_grid_init_with_cells :: proc(grid: ^Rect_Grid($Cell_Type), position: math.Vec2f, size: math.Vec2i, cell_size: math.Vec2f, allocator := context.allocator) {
    rect_grid_init_without_cells(grid, position, size, cell_size)
    grid.cells = make([]Cell_Type, grid.size.x * grid.size.y, allocator)
}

rect_grid_init_without_cells :: proc(grid: ^Rect_Grid($Cell_Type), position: math.Vec2f, size: math.Vec2i, cell_size: math.Vec2f) {
    grid.position = position
    grid.size = size
    grid.cell_size = cell_size
}

rect_grid_cell :: proc(grid: Rect_Grid($Cell_Type), grid_pos: math.Vec2i) -> Cell_Type {
    return grid.cells[grid_pos.y * grid.size.x + grid_pos.x]
}

rect_grid_cell_ptr :: proc(grid: ^Rect_Grid($Cell_Type), grid_pos: math.Vec2i) -> ^Cell_Type {
    return &grid.cells[grid_pos.y * grid.size.x + grid_pos.x]
}

rect_grid_set_cell :: proc(grid: ^Rect_Grid($Cell_Type), grid_pos: math.Vec2i, cell: Cell_Type) {
    grid.cells[grid_pos.y * grid.size.x + grid_pos.x] = cell
}

rect_grid_world_to_grid_position :: proc(grid: Rect_Grid($Cell_Type), world_position: math.Vec2f) -> (grid_position: math.Vec2i) {
    grid_position.x = math.floor_to_int((world_position.x - grid.position.x) / grid.cell_size.x)
    grid_position.y = math.floor_to_int((world_position.y - grid.position.y) / grid.cell_size.y)
    return grid_position
}

rect_grid_grid_to_world_position :: proc(grid: Rect_Grid($Cell_Type), grid_pos: math.Vec2i) -> (pos: math.Vec2f) {
    return grid.position + math.to_vec2f(grid_pos) * grid.cell_size
}