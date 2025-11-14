extends Control

# Leaderboard UI controller
# Handles displaying and refreshing leaderboard data

@onready var loading_label = $LeaderboardContainer/LoadingLabel
@onready var scores_list = $LeaderboardContainer/ScrollContainer/ScoresList
@onready var refresh_button = $LeaderboardContainer/ButtonContainer/RefreshButton
@onready var back_button = $LeaderboardContainer/ButtonContainer/BackButton

var is_loading = false

func _ready():
	# Focus the back button initially
	back_button.grab_focus()
	
	# Load leaderboard data
	_load_leaderboard()

func _load_leaderboard():
	if is_loading:
		return
		
	is_loading = true
	loading_label.visible = true
	refresh_button.disabled = true
	
	# Clear existing scores
	for child in scores_list.get_children():
		child.queue_free()
	
	print("Loading leaderboard data...")
	
	# Use LeaderboardManager to get scores
	if LeaderboardManager:
		var result = await LeaderboardManager.get_leaderboard()
		_display_leaderboard_result(result)
	else:
		_display_error("LeaderboardManager not available")

func _display_leaderboard_result(result):
	is_loading = false
	loading_label.visible = false
	refresh_button.disabled = false
	
	if result.has("error"):
		_display_error("Failed to load leaderboard: " + result.error)
		return
	
	if result.has("scores") and result.scores is Array:
		_display_scores(result.scores)
	else:
		_display_error("No leaderboard data available")

func _display_scores(scores: Array):
	if scores.is_empty():
		var no_scores_label = Label.new()
		no_scores_label.text = "No scores yet! Be the first to play!"
		no_scores_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		scores_list.add_child(no_scores_label)
		return
	
	# Display top scores
	for i in range(min(scores.size(), 10)):  # Show top 10
		var score_data = scores[i]
		var score_item = _create_score_item(i + 1, score_data)
		scores_list.add_child(score_item)

func _create_score_item(rank: int, score_data) -> Control:
	var item_container = HBoxContainer.new()
	
	# Rank label
	var rank_label = Label.new()
	rank_label.text = str(rank) + "."
	rank_label.custom_minimum_size.x = 40
	item_container.add_child(rank_label)
	
	# Player name (if available)
	var name_label = Label.new()
	if score_data.has("player_name"):
		name_label.text = score_data.player_name
	else:
		name_label.text = "Anonymous"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_container.add_child(name_label)
	
	# Score
	var score_label = Label.new()
	if score_data.has("score"):
		score_label.text = str(score_data.score)
	else:
		score_label.text = "0"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.custom_minimum_size.x = 100
	item_container.add_child(score_label)
	
	return item_container

func _display_error(message: String):
	var error_label = Label.new()
	error_label.text = message
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.modulate = Color.RED
	scores_list.add_child(error_label)

func _on_refresh_button_pressed():
	print("Refreshing leaderboard...")
	_load_leaderboard()

func _on_back_button_pressed():
	print("Returning to main menu...")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")