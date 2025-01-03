extends Node2D

@export var board : Node2D
@export var enemy_texture : Texture2D

var active_piece_type : String = "none"
var player_pieces = []
var enemy_timer : float = 0
var enemy_spawn_rate : float = 5
var enemy_count = 0
var score : int = 0
var piece_types = {
	"k" : "knight",
	"r" : "rook",
	"b" : "bishop",
	"q" : "queen",
	"x" : "king",
	"p" : "pawn",
}
var available_pieces = {
	"knight": 8,
	"rook": 8,
	"bishop": 8,
	"queen": 8,
	"king": 8,
	"pawn": 8,
}
var textures = {
	"knight": load("res://assets/WKnight.svg"),
	"rook": load("res://assets/WRook.svg"),
	"bishop": load("res://assets/WBishop.svg"),
	"queen": load("res://assets/WQueen.svg"),
	"king": load("res://assets/WKing.svg"),
	"pawn": load("res://assets/WPawn.svg"),
}

func _ready():
	$ScoreLabel.text = "Score: " + str(score)
	player_pieces = []
	pass

func _process(delta):
	enemy_timer += delta
	if enemy_timer > enemy_spawn_rate:
		enemy_timer = 0
		spawn_enemy()

	if Input.is_action_just_pressed("use_piece"):
		get_piece()

func _input(event):
	if event is InputEventMouseButton and event.pressed and active_piece_type != "none":
		print("Mouse clicked, active_piece_type: ", active_piece_type)
		var mouse_pos = get_global_mouse_position()
		var grid_pos = board.get_grid_pos(mouse_pos)
		place_piece(grid_pos)
		print(grid_pos)

func spawn_enemy():
	var random_pos = Vector2(randi_range(0,7),randi_range(0,7))
	while board.occupied_squares.get(random_pos, false):
		random_pos = Vector2(randi_range(0,7),randi_range(0,7))
	var square = board.get_square(random_pos)
	square.get_node("ColorRect/ContentTextureRect").texture = enemy_texture
	square.get_node("ColorRect/ContentTextureRect").visible = true
	board.occupied_squares[random_pos] = true
	enemy_count +=1

func get_piece():
	for key in piece_types.keys():
		if Input.is_action_just_pressed(key):
			if piece_types[key] in available_pieces and available_pieces[piece_types[key]] > 0:
				active_piece_type = piece_types[key]
				return
			else:
				print("No " + piece_types[key] + " available")


func place_piece(grid_pos : Vector2):
	if !board.occupied_squares.get(grid_pos, false):
		var square = board.get_square(grid_pos)
		square.get_node("ColorRect/ContentTextureRect").texture = textures[active_piece_type]
		square.get_node("ColorRect/ContentTextureRect").visible = true
		player_pieces.append({"type" : active_piece_type, "pos" : grid_pos})
		board.occupied_squares[grid_pos] = true
		available_pieces[active_piece_type] -= 1
		active_piece_type = "none"
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
		enemy_count -=1
		score +=1
		$ScoreLabel.text = "Score: " + str(score)


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
	var moves = []
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
	var moves = []
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
	var moves = []
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
	var moves = []
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
	var moves = []
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
	var moves = []
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
