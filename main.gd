extends Node2D

@export var board : Node
@export var enemy_texture : Texture2D

var active_piece_type : String = "none"
var player_pieces = []
var enemy_count = 15
var score : int = 0
var piece_types = {
	"k" : "knight",
	"r" : "rook", 
	"b" : "bishop",
	"q" : "queen",
	# "x" : "king",
	"p" : "pawn",
}
var available_pieces = {
	"knight": 2,
	"rook": 2,
	"bishop": 2,
	"queen": 1,
	"king": 1,
	"pawn": 8,
}
var textures = {
	"knight": load("res://assets/BKnight.svg"),
	"rook": load("res://assets/BRook.svg"),
	"bishop": load("res://assets/BBishop.svg"),
	"queen": load("res://assets/BQueen.svg"),
	"king": load("res://assets/BKing.svg"),
	"pawn": load("res://assets/BPawn.svg"),
}

func _ready():
	print("main's _ready")
	player_pieces = []
	# Spawn initial enemies
	for i in range(enemy_count):
		spawn_enemy()
	board.square_clicked.connect(_on_square_clicked)

func spawn_enemy():
	var random_pos = Vector2(randi_range(0,7),randi_range(0,7))
	while board.occupied_squares.get(random_pos, false):
		random_pos = Vector2(randi_range(0,7),randi_range(0,7))
	var square = board.get_square(random_pos)
	square.get_node("ColorRect/ContentTextureRect").texture = enemy_texture
	square.get_node("ColorRect/ContentTextureRect").visible = true
	board.occupied_squares[random_pos] = true

func _process(_delta):
	if Input.is_action_just_pressed("use_piece"):
		get_piece()

func get_piece():
	for key in piece_types.keys():
		if Input.is_action_just_pressed(key):
			if piece_types[key] in available_pieces and available_pieces[piece_types[key]] > 0:
				active_piece_type = piece_types[key]
				$SelectedPiece.text = "Selected Piece: " + active_piece_type
				return
			else:
				var popup = Popup.new()
				var label = Label.new()
				label.text = piece_types[key] + " not available"
				popup.add_child(label)
				add_child(popup)
				popup.popup_centered()
				
				# Create timer to close popup
				var timer = get_tree().create_timer(0.2)
				await timer.timeout
				popup.queue_free()

func _on_square_clicked(grid_pos: Vector2):
	if active_piece_type != "none":
		place_piece(grid_pos)
		board.clear_highlights()

func place_piece(grid_pos : Vector2):
	if !board.occupied_squares.get(grid_pos, false):
		var square = board.get_square(grid_pos)
		square.get_node("ColorRect/ContentTextureRect").texture = textures[active_piece_type]
		square.get_node("ColorRect/ContentTextureRect").visible = true
		player_pieces.append({"type" : active_piece_type, "pos" : grid_pos})
		board.occupied_squares[grid_pos] = true
		available_pieces[active_piece_type] -= 1
		$Available.text = str(available_pieces)
		active_piece_type = "none"
		$SelectedPiece.text = "Selected Piece: none"
		check_kills()
	else:
		print("Already occupied")

		
func check_kills():
	var killed_positions = []
	for piece_data in player_pieces:	
		var kills = get_moves(piece_data.type, piece_data.pos)
		for pos in kills:
			if board.occupied_squares.get(pos, false):
				killed_positions.append(pos)
	
	for pos in killed_positions:
		var square = board.get_square(pos)
		square.get_node("ColorRect/ContentTextureRect").texture = null
		square.get_node("ColorRect/ContentTextureRect").visible = false
		board.occupied_squares[pos] = false
		score += 1
		$ScoreLabel.text = "Score: " + str(score)
		# Respawn enemy in new position
		spawn_enemy()


func get_moves(piece_type : String, grid_position : Vector2) -> Array[Vector2]:
	match piece_type:
		"knight":
			return get_knight_moves(grid_position)
		"rook":
			return get_rook_moves(grid_position)
		"bishop":
			return get_bishop_moves(grid_position)
		"queen":
			return get_queen_moves(grid_position)
		"king":
			return get_king_moves(grid_position)
		"pawn":
			return get_pawn_moves(grid_position)
	return []
	

func get_knight_moves(grid_position : Vector2) -> Array[Vector2]:
	var moves : Array[Vector2] = []
	var directions = [
		Vector2(-2, -1), Vector2(-2, 1),
		Vector2(-1, -2), Vector2(-1, 2),
		Vector2(1, -2), Vector2(1, 2),
		Vector2(2, -1), Vector2(2, 1)
	]
	for dir in directions:
		var new_pos = grid_position + dir
		if new_pos.x >= 0 and new_pos.x < 8 and new_pos.y >= 0 and new_pos.y < 8:
			moves.append(new_pos)
	return moves

func get_rook_moves(grid_position : Vector2) -> Array[Vector2]:
	var moves : Array[Vector2] = []
	var directions = [
		Vector2(1,0), Vector2(-1,0),Vector2(0,1), Vector2(0,-1)
	]

	for dir in directions:
		var current_pos = grid_position + dir
		while current_pos.x >= 0 and current_pos.x < 8 and current_pos.y >= 0 and current_pos.y < 8:
			moves.append(current_pos)
			current_pos += dir
	return moves
	
func get_bishop_moves(grid_position : Vector2) -> Array[Vector2]:
	var moves : Array[Vector2] = []
	var directions = [
		Vector2(1,1), Vector2(-1,-1),Vector2(1,-1), Vector2(-1,1)
	]

	for dir in directions:
		var current_pos = grid_position + dir
		while current_pos.x >= 0 and current_pos.x < 8 and current_pos.y >= 0 and current_pos.y < 8:
			moves.append(current_pos)
			current_pos += dir
	return moves
	
func get_queen_moves(grid_position : Vector2) -> Array[Vector2]:
	var moves : Array[Vector2] = []
	var directions = [
		Vector2(1,0), Vector2(-1,0),Vector2(0,1), Vector2(0,-1),
		Vector2(1,1), Vector2(-1,-1),Vector2(1,-1), Vector2(-1,1)
	]

	for dir in directions:
		var current_pos = grid_position + dir
		while current_pos.x >= 0 and current_pos.x < 8 and current_pos.y >= 0 and current_pos.y < 8:
			moves.append(current_pos)
			current_pos += dir
	return moves

func get_king_moves(grid_position : Vector2) -> Array[Vector2]:
	var moves : Array[Vector2] = []
	var directions = [
		Vector2(1,0), Vector2(-1,0),Vector2(0,1), Vector2(0,-1),
		Vector2(1,1), Vector2(-1,-1),Vector2(1,-1), Vector2(-1,1)
	]
	for dir in directions:
		var new_pos = grid_position + dir
		if new_pos.x >= 0 and new_pos.x < 8 and new_pos.y >= 0 and new_pos.y < 8:
			moves.append(new_pos)
	return moves

func get_pawn_moves(grid_position : Vector2) -> Array[Vector2]:
	var moves : Array[Vector2] = []
	var move_direction = -1
	var new_pos = grid_position + Vector2(0,move_direction)
	if new_pos.x >= 0 and new_pos.x < 8 and new_pos.y >= 0 and new_pos.y < 8:
		moves.append(new_pos)
		if grid_position.y == (4 + move_direction):
			new_pos = grid_position + Vector2(0,move_direction*2)
			if new_pos.x >= 0 and new_pos.x < 8 and new_pos.y >= 0 and new_pos.y < 8:
				moves.append(new_pos)
	new_pos = grid_position + Vector2(1,move_direction)
	if new_pos.x >= 0 and new_pos.x < 8 and new_pos.y >= 0 and new_pos.y < 8:
		moves.append(new_pos)
	new_pos = grid_position + Vector2(-1,move_direction)
	if new_pos.x >= 0 and new_pos.x < 8 and new_pos.y >= 0 and new_pos.y < 8:
		moves.append(new_pos)
	return moves
