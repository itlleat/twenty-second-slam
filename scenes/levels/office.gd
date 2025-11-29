extends Node2D

# Office level - bullet hell boss fight

func _ready():
	print("Office level loaded")
	# Start the game timer
	GameManager.start_game()
	
	var audio_manager = get_node("GlobalAudioManager")
	
	audio_manager.play_game_music()

	# Connect game ended signal to show game over screen
	if GameManager.has_signal("game_ended"):
		GameManager.game_ended.connect(_on_game_ended)

func _on_game_ended(_final_score):
	get_tree().change_scene_to_file("res://scenes/ui/game_over.tscn")
