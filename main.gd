extends Node2D

signal piece_unavailable(piece_name: String)

@export var board : Node
@export var enemy_texture : Texture2D

var active_piece_type : String = "none"
var player_pieces : Array[Dictionary] = []
var enemy_count : int = 15
var score : int = 0
const BOARD_SIZE : int = 8
const FLASH_DURATION : float = 0.2
const RESPAWN_DELAY : float = 0.3

var piece_types : Dictionary = {
	"k" : "knight",
	"r" : "rook", 
	"b" : "bishop",
	"q" : "queen",
	"p" : "pawn",
}

var available_pieces : Dictionary = {
	"knight": 2,
	"rook": 2,
	"bishop": 2,
	"queen": 1,
	# "king": 1,
	"pawn": 4,
}

var textures : Dictionary = {
	"knight": preload("res://assets/WKnight.svg"),
	"rook": preload("res://assets/WRook.svg"),
	"bishop": preload("res://assets/WBishop.svg"),
	"queen": preload("res://assets/WQueen.svg"),
	"king": preload("res://assets/WKing.svg"),
	"pawn": preload("res://assets/WPawn.svg"),
}

var flashing_squares = {}

var game_seed: int 

var rng: RandomNumberGenerator

var elapsed_time: float = 0.0
var stopwatch_active: bool = false

func _ready() -> void:
	rng = RandomNumberGenerator.new()
	game_seed = GameState.current_seed
	rng.seed = game_seed
	$"seed".text = str(game_seed)
	$"seed".text_submitted.connect(_on_seed_submitted)
	$ResetButton.pressed.connect(_on_reset_pressed)
	
	player_pieces.clear()
	board.square_clicked.connect(_on_square_clicked)
	piece_unavailable.connect(_on_piece_unavailable)
	
	for i in enemy_count:
		spawn_enemy(false)  

	update_score_and_time_history()
	stopwatch_active = true

func set_seed(new_seed: int) -> void:
	game_seed = new_seed
	GameState.current_seed = new_seed
	rng.seed = game_seed

func _on_seed_submitted(new_seed) -> void:
	if new_seed.is_valid_int():
		print("reached to int, seed on signal submit :"+ str(game_seed))
		set_seed(new_seed.to_int())
		get_tree().reload_current_scene()
		print("just after reload:"+str(game_seed))
	else:
		$"seed".text = str(game_seed)

func spawn_enemy(should_flash: bool = true) -> void:
	var empty_positions = _get_empty_positions()
	if empty_positions.is_empty():
		return
		
	var random_pos = empty_positions[rng.randi() % empty_positions.size()]
	var square = board.get_square(random_pos)
	var color_rect = square.get_node("ColorRect")
	
	
	if should_flash:
		_cleanup_flashing_squares() 
		await _flash_square(color_rect)
	
	var content = square.get_node("ColorRect/ContentTextureRect")
	content.texture = enemy_texture
	content.visible = true
	board.occupied_squares[random_pos] = true
	board.occupied_by_piece[random_pos] = "enemy"

func _flash_square(color_rect: ColorRect) -> void:
	var original_color = color_rect.color
	flashing_squares[color_rect] = original_color
	color_rect.color = Color("#12f2c9b3") 
	await get_tree().create_timer(FLASH_DURATION).timeout
	
	if color_rect in flashing_squares:
		color_rect.color = original_color
		flashing_squares.erase(color_rect)

func _cleanup_flashing_squares() -> void:
	for color_rect in flashing_squares:
		color_rect.color = flashing_squares[color_rect]
	flashing_squares.clear()

func _get_empty_positions() -> Array:
	var empty = []
	for x in BOARD_SIZE:
		for y in BOARD_SIZE:
			var pos = Vector2(x, y)
			if not board.occupied_squares.get(pos, false):
				empty.append(pos)
	return empty

func _process(delta: float) -> void:
	if stopwatch_active:
		elapsed_time += delta
		update_stopwatch_display()
	if Input.is_action_just_pressed("use_piece"):
		get_piece()

func update_stopwatch_display() -> void:
	var minutes = int(elapsed_time / 60)
	var seconds = int(elapsed_time) % 60
	$StopwatchLabel.text = "Time: %d:%02d" % [minutes, seconds]

func get_piece() -> void:
	for key in piece_types:
		if Input.is_action_just_pressed(key):
			var piece_name = piece_types[key]
			if piece_name in available_pieces and available_pieces[piece_name] > 0:
				# Remove previous piece if it exists
				for piece in player_pieces:
					var square = board.get_square(piece.pos)
					var content = square.get_node("ColorRect/ContentTextureRect")
					content.texture = null
					content.visible = false
					board.occupied_squares[piece.pos] = false
					board.occupied_by_piece[piece.pos] = "none"
				player_pieces.clear()
				
				active_piece_type = piece_name
				$SelectedPiece.text = "Selected Piece: " + active_piece_type
			else:
				var is_game_over = await check_game_over()
				if not is_game_over:
					piece_unavailable.emit(piece_name)

func _on_piece_unavailable(piece_name: String) -> void:
	var popup = Popup.new()
	var label = Label.new()
	label.text = piece_name + " not available"
	label.add_theme_font_size_override("font_size", 70)  # Increased font size
	popup.add_child(label)
	add_child(popup)
	popup.popup_centered()
	
	await get_tree().create_timer(FLASH_DURATION).timeout
	popup.queue_free()

func _on_square_clicked(grid_pos: Vector2) -> void:
	if active_piece_type != "none":
		place_piece(grid_pos)
		board.clear_highlights()

func place_piece(grid_pos: Vector2) -> void:
	if board.occupied_squares.get(grid_pos, false):
		return
	
	var square = board.get_square(grid_pos)
	var content = square.get_node("ColorRect/ContentTextureRect")
	content.texture = textures[active_piece_type]
	content.visible = true
	
	player_pieces.append({"type": active_piece_type, "pos": grid_pos})
	board.occupied_squares[grid_pos] = true
	board.occupied_by_piece[grid_pos] = "player"
	available_pieces[active_piece_type] -= 1
	
	$Available.text = str(available_pieces)
	active_piece_type = "none"
	$SelectedPiece.text = "Selected Piece: none"
	
	check_kills()

func check_kills() -> void:
	var killed_positions = _get_killed_positions()
	
	if killed_positions.is_empty():
		return
		
	# Handle all kills at once
	for pos in killed_positions:
		var square = board.get_square(pos)
		var content = square.get_node("ColorRect/ContentTextureRect")
		content.texture = null
		content.visible = false
		board.occupied_squares[pos] = false
		score += 1
	
	$ScoreLabel.text = "Score: " + str(score)
	
	# Wait a moment before respawning
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	
	# Respawn enemies until we're back to enemy_count
	var current_enemies = count_enemies()
	var enemies_to_spawn = enemy_count - current_enemies
	
	for i in enemies_to_spawn:
		spawn_enemy(true)
		# Add a small delay between spawns
		await get_tree().create_timer(0.1).timeout

func count_enemies() -> int:
	var count = 0
	for pos in board.occupied_squares:
		if board.occupied_squares[pos]:
			var square = board.get_square(pos)
			var content = square.get_node("ColorRect/ContentTextureRect")
			if content.texture == enemy_texture:
				count += 1
	return count

func _get_killed_positions() -> Array:
	var killed = []
	for piece in player_pieces:
		var kills = get_moves(piece.type, piece.pos)
		for pos in kills:
			if board.occupied_squares.get(pos, false) and board.occupied_by_piece[pos] == "enemy":
				killed.append(pos)
	return killed

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


func get_current_seed() -> int:
	return game_seed

func _on_reset_pressed() -> void:
	GameState.score_history.append(score)
	GameState.time_history.append(elapsed_time)
	get_tree().reload_current_scene()

func update_score_and_time_history() -> void:
	var score_history = GameState.score_history
	var time_history = GameState.time_history
	var history_text = "History:\n"
	for i in range(score_history.size()):
		var minutes = int(time_history[i] / 60)
		var seconds = int(time_history[i]) % 60
		history_text += "Score: %d - Time: %d:%02d\n" % [score_history[i], minutes, seconds]
	$ScoreHistoryLabel.text = history_text

func check_game_over() -> bool:
	for piece_name in available_pieces:
		if available_pieces[piece_name] > 0:
			return false
	stopwatch_active = false
	$GameOverPopup.popup_centered()
	await get_tree().create_timer(1.0).timeout
	_on_reset_pressed()
	return true
