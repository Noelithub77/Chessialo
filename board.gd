extends GridContainer
@export var square_scene : PackedScene
signal square_clicked(grid_pos: Vector2)

var grid = []
var square_size = 64  
var board_size = 8
var occupied_squares = {}
var occupied_by_piece = {}
var preview_opacity = 0.5
var highlight_color = Color(0.2, 0.8, 0.2, 0.3)  # Semi-transparent green
var original_colors = {}

func _ready():
	create_grid()

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
			button.connect("mouse_entered", Callable(self, "_on_button_mouse_entered").bind(Vector2(col, row)))
			button.connect("mouse_exited", Callable(self, "_on_button_mouse_exited").bind(Vector2(col, row)))
			
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

func highlight_squares(positions: Array[Vector2]):
	clear_highlights()
	for pos in positions:
		var square = get_square(pos)
		if square:
			var color_rect = square.get_node("ColorRect")
			original_colors[pos] = color_rect.color
			color_rect.color = highlight_color

func clear_highlights():
	for pos in original_colors.keys():
		var square = get_square(pos)
		if square:
			var color_rect = square.get_node("ColorRect")
			color_rect.color = original_colors[pos]
	original_colors.clear()

func _on_button_mouse_entered(grid_pos: Vector2):
	var square = get_square(grid_pos)
	if square:
		var main = get_tree().get_root().get_node("Main")
		if main.active_piece_type != "none":
			# Show piece preview
			if !occupied_squares[grid_pos]:
				var texture_rect = square.get_node("ColorRect/ContentTextureRect")
				texture_rect.texture = main.textures[main.active_piece_type]
				texture_rect.visible = true
				texture_rect.modulate.a = preview_opacity
			
			# Show move highlights
			var moves = main.get_moves(main.active_piece_type, grid_pos)
			highlight_squares(moves)

func _on_button_mouse_exited(grid_pos: Vector2):
	var square = get_square(grid_pos)
	if square and !occupied_squares[grid_pos]:
		var texture_rect = square.get_node("ColorRect/ContentTextureRect")
		texture_rect.texture = null
		texture_rect.visible = false
		texture_rect.modulate.a = 1
	clear_highlights()
