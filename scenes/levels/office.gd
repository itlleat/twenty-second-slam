extends Node2D

# Office level - bullet hell boss fight

func _ready():
	print("Office level loaded")
	# Start the game timer
	GameManager.start_game()
	var audio_manager = get_node("GlobalAudioManager")
	audio_manager.play_game_music()
