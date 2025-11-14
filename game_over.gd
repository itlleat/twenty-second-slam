extends Control

# Game Over Screen - Shows final score and allows score submission

@onready var final_score_label: Label = $VBoxContainer/FinalScoreLabel
@onready var name_input: LineEdit = $VBoxContainer/NameInput
@onready var submit_button: Button = $VBoxContainer/HBoxContainer/SubmitButton
@onready var menu_button: Button = $VBoxContainer/HBoxContainer/MenuButton
@onready var leaderboard_button: Button = $VBoxContainer/HBoxContainer/LeaderboardButton
@onready var status_label: Label = $VBoxContainer/StatusLabel

var final_score: int = 0

func _ready():
	# Connect signals
	submit_button.pressed.connect(_on_submit_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)
	leaderboard_button.pressed.connect(_on_leaderboard_button_pressed)
	
	# Connect to LeaderboardManager
	LeaderboardManager.score_submitted.connect(_on_score_submitted)
	
	# Connect to GameManager for game end
	GameManager.game_ended.connect(_on_game_ended)
	
	# Set up initial UI state
	name_input.placeholder_text = "Enter your name (max 32 chars)"
	name_input.max_length = 32
	status_label.text = ""
	
	# Initially hide this screen
	hide()

func _on_game_ended(score: int):
	"""Called when the game ends with final score"""
	final_score = score
	final_score_label.text = "Final Score: " + str(final_score)
	
	# Clear previous input and status
	name_input.text = ""
	status_label.text = ""
	submit_button.disabled = false
	
	# Show the game over screen
	show()
	
	# Focus on name input for easy typing
	name_input.grab_focus()

func _on_submit_button_pressed():
	"""Submit score to leaderboard"""
	var player_name = name_input.text.strip_edges()
	
	if player_name.is_empty():
		status_label.text = "Please enter your name!"
		status_label.modulate = Color.RED
		return
	
	# Disable submit button to prevent double submission
	submit_button.disabled = true
	status_label.text = "Submitting score..."
	status_label.modulate = Color.YELLOW
	
	# Submit to leaderboard
	LeaderboardManager.submit_score(player_name, final_score)

func _on_score_submitted(success: bool, message: String):
	"""Handle score submission result"""
	if success:
		status_label.text = "Score submitted successfully!"
		status_label.modulate = Color.GREEN
		# Keep submit button disabled since score was submitted
	else:
		status_label.text = "Error: " + message
		status_label.modulate = Color.RED
		# Re-enable submit button to allow retry
		submit_button.disabled = false

func _on_menu_button_pressed():
	"""Return to main menu"""
	# Reset game state
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_leaderboard_button_pressed():
	"""Go to leaderboard screen"""
	get_tree().change_scene_to_file("res://leaderboard.tscn")

# Handle Enter key in name input
func _on_name_input_text_submitted(new_text: String):
	if not submit_button.disabled and not new_text.strip_edges().is_empty():
		_on_submit_button_pressed()