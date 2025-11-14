extends Control

# Game UI - Displays score and timer during gameplay

@onready var score_label: Label = $VBoxContainer/ScoreLabel
@onready var timer_label: Label = $VBoxContainer/TimerLabel

func _ready():
	# Connect to GameManager signals
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.time_changed.connect(_on_time_changed)
	GameManager.game_started.connect(_on_game_started)
	GameManager.game_ended.connect(_on_game_ended)
	
	# Initialize display
	_update_score_display(0)
	_update_timer_display(20.0)

func _on_score_changed(new_score: int):
	_update_score_display(new_score)

func _on_time_changed(time_left: float):
	_update_timer_display(time_left)

func _on_game_started():
	print("GameUI: Game started")
	show()

func _on_game_ended(final_score: int):
	print("GameUI: Game ended with score: ", final_score)
	# Keep showing final score for a moment before transitioning

func _update_score_display(score: int):
	if score_label:
		score_label.text = "Score: " + str(score)

func _update_timer_display(time_left: float):
	if timer_label:
		var total_seconds = int(time_left)
		var minutes = total_seconds / 60
		var seconds = total_seconds % 60
		var centiseconds = int((time_left - int(time_left)) * 100)
		
		if minutes > 0:
			timer_label.text = "Time: %d:%02d.%02d" % [minutes, seconds, centiseconds]
		else:
			timer_label.text = "Time: %d.%02d" % [seconds, centiseconds]
		
		# Change color when time is running out
		if time_left <= 5.0:
			timer_label.modulate = Color.RED
		elif time_left <= 10.0:
			timer_label.modulate = Color.ORANGE
		else:
			timer_label.modulate = Color.WHITE