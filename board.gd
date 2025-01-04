extends GridContainer
@export var square_scene : PackedScene
signal square_clicked(grid_pos: Vector2)

@export var grid = []
var square_size = 64  
var board_size = 8
var occupied_squares = {}
var occupied_by_piece = {}


func _ready():
	create_grid()
	print("board's _ready")
	#_on_square_pressed(Vector2(6,6))

func create_grid():
	for row in range(board_size):
		for col in range(board_size):
			var square_instance = square_scene.instantiate()
			square_instance.name = str(Vector2(col,row)) 
			var color = Color.WHITE if (row + col) % 2 == 0 else Color.DARK_GRAY
			# Update to reference ColorRect directly
			var color_rect = square_instance.get_node("ColorRect")
			color_rect.color = color
			# Get button as child of ColorRect
			var button = color_rect.get_node("Button")
			button.connect("pressed", Callable(self, "on_square_pressed").bind(Vector2(col, row)))
			
			# Set position for each square
			square_instance.position = Vector2(col * square_size, row * square_size)
			
			add_child(square_instance)
			grid.append(square_instance)
			occupied_squares[Vector2(col,row)] = false
			occupied_by_piece[Vector2(col,row)] = "none"

func on_square_pressed(grid_pos: Vector2):
	square_clicked.emit(grid_pos)
	print("Square clicked at: ", grid_pos)

func get_square(grid_pos: Vector2):
	var index = grid_pos.y * board_size + grid_pos.x
	if index >= 0 and index < grid.size():
		return grid[index]
	return null

	
