extends GridContainer

@export var square_scene : PackedScene

var grid = []
var square_size = Vector2(64, 64)
var board_size = 8
var occupied_squares = {}
var occupied_by_piece = {}


func _ready():
	create_grid()

func create_grid():
	for row in range(board_size):
		for col in range(board_size):
			var square_instance = square_scene.instantiate()
			var color = Color.WHITE if (row + col) % 2 == 0 else Color.DARK_GRAY
			square_instance.get_node("ColorRect").color = color
			square_instance.position = Vector2(col * square_size.x, row * square_size.y)
			add_child(square_instance)
			grid.append(square_instance)
			occupied_squares[Vector2(col,row)] = false
			occupied_by_piece[Vector2(col,row)] = "none"


func get_grid_pos(world_position: Vector2) -> Vector2:
	var board_pos = world_position - position
	var col = int(board_pos.x / square_size.x)
	var row = int(board_pos.y / square_size.y)
	return Vector2(col,row)

func get_world_pos(grid_position: Vector2) -> Vector2:
	return grid_position * square_size + position + square_size/2

func get_square(grid_pos: Vector2):
	var index = grid_pos.y * board_size + grid_pos.x
	if index >= 0 and index < grid.size():
		return grid[index]
	return null
