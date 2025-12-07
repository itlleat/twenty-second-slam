extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func play_game_music():
	var music_player = get_node("GameplayMusicStream")
	if music_player:
		music_player.play()

func play_heavy_punch_sfx():
	var punch_stream = get_node("PowerPunchStream")
	if punch_stream:
		punch_stream.play()
