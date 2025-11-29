extends Control

# Game Over screen controller
# Handles final score display and navigation options

@onready var score_label = $GameOverContainer/ScoreLabel
@onready var high_score_label = $GameOverContainer/HighScoreLabel
@onready var play_again_button = $GameOverContainer/ButtonContainer/PlayAgainButton
@onready var points_label = $GameOverContainer/PlayerPointsLabel

# Add name entry and leaderboard container
@onready var name_entry = $GameOverContainer/NameEntry
@onready var leaderboard_container = $GameOverContainer/LeaderboardContainer
@onready var submit_button = $GameOverContainer/SubmitButton

var final_score: int = 0
var final_points: int = 0

func _ready():
	# Get final score from GameManager if available
	if GameManager:
		final_score = GameManager.total_damage
		final_points = GameManager.player_points
	
	# Display scores
	score_label.text = "Final Score: " + str(final_score)
	points_label.text = "Player Points: " + str(final_points)
	
	# Get high score (you can implement persistent storage later)
	var high_score = _get_high_score()
	high_score_label.text = "High Score: " + str(high_score)
	
	# Check if this is a new high score
	if final_score > high_score:
		high_score_label.text = "NEW HIGH SCORE: " + str(final_score)
		high_score_label.modulate = Color.YELLOW
		_save_high_score(final_score)
	
	# Focus the play again button
	play_again_button.grab_focus()

	# Show name entry and leaderboard after game over
	name_entry.visible = true
	leaderboard_container.visible = true
	submit_button.visible = true
	# Connect leaderboard and score submission signals
	if LeaderboardManager:
		LeaderboardManager.scores_retrieved.connect(_on_scores_retrieved)
		LeaderboardManager.score_submitted.connect(_on_score_submitted)
	submit_button.pressed.connect(_on_submit_button_pressed)


func _on_submit_button_pressed():
	var player_name = name_entry.text if name_entry.text != "" else "Anonymous"
	print("Submitting player points to leaderboard: ", final_points, " Name: ", player_name)
	if LeaderboardManager:
		LeaderboardManager.submit_score(player_name, final_points)

func _on_score_submitted(success, message):
	print("Score submission result: ", success, message)
	if success and LeaderboardManager:
		LeaderboardManager.get_leaderboard()

func _get_high_score() -> int:
	# Simple high score storage - you can enhance this later
	if SettingsManager and SettingsManager.has_method("get_high_score"):
		return SettingsManager.get_high_score()
	return 0

func _save_high_score(score: int):
	# Simple high score storage - you can enhance this later
	if SettingsManager and SettingsManager.has_method("set_high_score"):
		SettingsManager.set_high_score(score)


func _on_scores_retrieved(scores):
	# Clear previous leaderboard entries
	for child in leaderboard_container.get_children():
		child.queue_free()
	if scores and typeof(scores) == TYPE_ARRAY:
		for i in range(min(scores.size(), 10)):
			var score_data = scores[i]
			var entry = HBoxContainer.new()
			var rank_label = Label.new()
			rank_label.text = str(i+1) + "."
			rank_label.custom_minimum_size.x = 40
			entry.add_child(rank_label)
			var name_label = Label.new()
			if score_data.has("player_name"):
				name_label.text = score_data.player_name
			else:
				name_label.text = "Anonymous"
			name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			entry.add_child(name_label)
			var entry_points_label = Label.new()
			if score_data.has("score"):
				entry_points_label.text = str(score_data.score) + " pts"
			else:
				entry_points_label.text = "0 pts"
			entry_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			entry_points_label.custom_minimum_size.x = 120
			entry.add_child(entry_points_label)
			leaderboard_container.add_child(entry)
	else:
		var error_label = Label.new()
		error_label.text = "No leaderboard data available"
		error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		error_label.modulate = Color.RED
		leaderboard_container.add_child(error_label)

func _on_play_again_button_pressed():
	print("Starting new game...")
	get_tree().change_scene_to_file("res://scenes/levels/office.tscn")

func _on_leaderboard_button_pressed():
	print("Opening leaderboards...")
	get_tree().change_scene_to_file("res://scenes/ui/leaderboard.tscn")

func _on_main_menu_button_pressed():
	print("Returning to main menu...")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
