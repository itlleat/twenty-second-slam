extends Node

# Game Manager - Singleton for tracking game state and score
signal game_started
signal game_ended(final_score)
signal score_changed(new_score)
signal time_changed(time_left)

var game_duration = 20.0  # 20 seconds
var game_timer = 0.0
var total_damage = 0
var player_points = 0
var is_game_active = false
var is_game_over = false

func _ready():
	# Make sure this persists between scenes
	set_process(false)  # Don't process until game starts

func _process(delta):
	if is_game_active and not is_game_over:
		game_timer += delta
		var time_left = max(0, game_duration - game_timer)
		emit_signal("time_changed", time_left)
		if time_left <= 0:
			end_game()

func start_game():
	"""Start a new game session"""
	print("GameManager: Starting new game")
	game_timer = 0.0
	total_damage = 0
	player_points = 0
	is_game_active = true
	is_game_over = false
	set_process(true)
	emit_signal("game_started")
	emit_signal("score_changed", total_damage)
	emit_signal("time_changed", game_duration)

func end_game():
	"""End the current game session"""
	if is_game_over:
		return  # Prevent multiple calls
		
	print("GameManager: Game ended with score: ", total_damage)
	is_game_active = false
	is_game_over = true
	set_process(false)
	emit_signal("game_ended", total_damage)
	# Scene transition should be handled by the game over UI, not here

func add_damage(damage_amount):
	"""Add damage to the total score"""
	if not is_game_active or is_game_over:
		return
		
	total_damage += damage_amount
	add_points(damage_amount)
	print("GameManager: Damage added: ", damage_amount, " Total: ", total_damage)
	emit_signal("score_changed", total_damage)

func add_points(amount):
	player_points += amount
	print("GameManager: Points added: ", amount, " Total points: ", player_points)
func get_current_score():
	"""Get the current total damage score"""
	return total_damage

func get_time_left():
	"""Get remaining time in seconds"""
	if not is_game_active:
		return game_duration
	return max(0, game_duration - game_timer)

func reset_game():
	"""Reset game state for new game"""
	game_timer = 0.0
	total_damage = 0
	player_points = 0
	is_game_active = false
	is_game_over = false
	set_process(false)
