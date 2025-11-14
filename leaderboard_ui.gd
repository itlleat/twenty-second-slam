extends Control

# Leaderboard UI - Display high scores from Purple Token API

@onready var score_list: VBoxContainer = $VBoxContainer/ScrollContainer/ScoreList
@onready var back_button: Button = $VBoxContainer/BackButton
@onready var loading_label: Label = $VBoxContainer/LoadingLabel

# Leaderboard UI for displaying high scores

func _ready():
	# Connect signals
	back_button.pressed.connect(_on_back_button_pressed)
	LeaderboardManager.scores_retrieved.connect(_on_scores_retrieved)
	
	# Load leaderboard
	load_leaderboard()

func load_leaderboard():
	"""Load leaderboard data from Purple Token API"""
	loading_label.visible = true
	loading_label.text = "Loading leaderboard..."
	
	# Clear existing scores
	for child in score_list.get_children():
		child.queue_free()
	
	# Fetch scores
	LeaderboardManager.get_leaderboard(20)  # Get top 20 scores

func _on_scores_retrieved(scores: Array):
	"""Handle leaderboard data received from API"""
	loading_label.visible = false
	
	if scores.is_empty():
		loading_label.visible = true
		loading_label.text = "No scores available or failed to load."
		return
	
	# Clear any existing score entries
	for child in score_list.get_children():
		child.queue_free()
	
	# Wait one frame for cleanup
	await get_tree().process_frame
	
	# Create score entries
	for i in range(scores.size()):
		var score_data = scores[i]
		var entry = create_score_entry(i + 1, score_data)
		score_list.add_child(entry)

func create_score_entry(rank: int, score_data: Dictionary) -> Control:
	"""Create a score entry UI element"""
	var entry = HBoxContainer.new()
	entry.add_theme_constant_override("separation", 20)
	
	# Rank label
	var rank_label = Label.new()
	rank_label.text = str(rank) + "."
	rank_label.custom_minimum_size.x = 40
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	entry.add_child(rank_label)
	
	# Player name label
	var name_label = Label.new()
	name_label.text = score_data.get("player", "Unknown")
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.add_child(name_label)
	
	# Score label
	var score_label = Label.new()
	score_label.text = str(score_data.get("score", 0))
	score_label.custom_minimum_size.x = 100
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	entry.add_child(score_label)
	
	# Date label (if available)
	if score_data.has("date"):
		var date_label = Label.new()
		var date_str = score_data.date
		# Format the date to be more readable (remove seconds)
		if ":" in date_str:
			var parts = date_str.split(" ")
			if parts.size() >= 2:
				var time_parts = parts[1].split(":")
				if time_parts.size() >= 2:
					date_str = parts[0] + " " + time_parts[0] + ":" + time_parts[1]
		date_label.text = date_str
		date_label.custom_minimum_size.x = 120
		date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		entry.add_child(date_label)
	
	# Color coding for top 3
	match rank:
		1:
			rank_label.modulate = Color.GOLD
			name_label.modulate = Color.GOLD
			score_label.modulate = Color.GOLD
		2:
			rank_label.modulate = Color.SILVER
			name_label.modulate = Color.SILVER
			score_label.modulate = Color.SILVER
		3:
			rank_label.modulate = Color("#CD7F32")  # Bronze
			name_label.modulate = Color("#CD7F32")
			score_label.modulate = Color("#CD7F32")
	
	return entry

func _on_back_button_pressed():
	"""Return to main menu"""
	get_tree().change_scene_to_file("res://main_menu.tscn")