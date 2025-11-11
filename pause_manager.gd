extends Node

# Pause Manager - Add this to your game scenes to handle pause input
# This script manually controls the pause state and communicates with the pause menu

@onready var pause_menu: Control = null

func _ready():
	# Find the pause menu in the scene
	pause_menu = get_tree().get_first_node_in_group("pause_menu")
	
	# If not found by group, try to find it by path (adjust path as needed)
	if not pause_menu:
		var ui_layer = get_tree().get_first_node_in_group("ui_layer")
		if ui_layer:
			pause_menu = ui_layer.get_node_or_null("PauseMenu")
	
	# Last resort: search by name in current scene
	if not pause_menu:
		pause_menu = get_tree().current_scene.find_child("PauseMenu", true, false)
	
	if not pause_menu:
		print("Warning: PauseManager could not find PauseMenu node!")

func _input(event):
	# Handle your custom "pause" input action
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	if not pause_menu:
		print("Cannot pause: PauseMenu not found!")
		return
	
	if pause_menu.is_paused:
		resume_game()
	else:
		pause_game()

func pause_game():
	if not pause_menu:
		return
		
	print("PauseManager: Pausing game")
	pause_menu.pause_game()

func resume_game():
	if not pause_menu:
		return
		
	print("PauseManager: Resuming game")
	pause_menu.resume_game()

# Public methods for other scripts to use
func is_game_paused() -> bool:
	if pause_menu:
		return pause_menu.is_paused
	return false

func force_pause():
	pause_game()

func force_resume():
	resume_game()