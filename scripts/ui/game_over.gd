extends Control

# Game Over screen controller
# Handles final score display and navigation options

@onready var score_label = $GameOverContainer/ScoreLabel
@onready var high_score_label = $GameOverContainer/HighScoreLabel
@onready var play_again_button = $GameOverContainer/ButtonContainer/PlayAgainButton

var final_score: int = 0

func _ready():
	# Get final score from GameManager if available
	if GameManager:
		final_score = GameManager.current_damage
	
	# Display scores
	score_label.text = "Final Score: " + str(final_score)
	
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
	
	# Submit score to leaderboard if possible
	if LeaderboardManager:
		_submit_score_to_leaderboard()

func _get_high_score() -> int:
	# Simple high score storage - you can enhance this later
	if SettingsManager and SettingsManager.has_method("get_high_score"):
		return SettingsManager.get_high_score()
	return 0

func _save_high_score(score: int):
	# Simple high score storage - you can enhance this later
	if SettingsManager and SettingsManager.has_method("set_high_score"):
		SettingsManager.set_high_score(score)

func _submit_score_to_leaderboard():
	print("Submitting score to leaderboard: ", final_score)
	# You can implement automatic leaderboard submission here
	# For now, just print the score

func _on_play_again_button_pressed():
	print("Starting new game...")
	get_tree().change_scene_to_file("res://scenes/levels/office.tscn")

func _on_leaderboard_button_pressed():
	print("Opening leaderboards...")
	get_tree().change_scene_to_file("res://scenes/ui/leaderboard.tscn")

func _on_main_menu_button_pressed():
	print("Returning to main menu...")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
