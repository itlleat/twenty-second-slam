extends Control

# Pause Menu Controller
# Handles game pausing, resume, restart, settings, and main menu navigation
# Call pause_game() and resume_game() from external scripts to control pause state

@onready var pause_panel = $PausePanel
@onready var settings_panel = $SettingsPanel
@onready var volume_slider = $SettingsPanel/SettingsContainer/VolumeContainer/VolumeSlider
@onready var fullscreen_checkbox = $SettingsPanel/SettingsContainer/FullscreenCheckbox

var is_paused = false
var current_level_scene: String = ""

func _ready():
	# Store the current scene path for restart functionality
	current_level_scene = get_tree().current_scene.scene_file_path
	
	# Initialize settings
	_load_settings()
	
	# Ensure both panels start hidden
	pause_panel.visible = true
	settings_panel.visible = false
	
	# Start with the pause menu hidden
	visible = false

func _load_settings():
	# Load volume setting
	var master_bus = AudioServer.get_bus_index("Master")
	var volume_db = AudioServer.get_bus_volume_db(master_bus)
	var volume_linear = db_to_linear(volume_db)
	volume_slider.value = volume_linear * 100
	
	# Load fullscreen setting
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		fullscreen_checkbox.button_pressed = true
	else:
		fullscreen_checkbox.button_pressed = false

# Removed automatic input handling - pause menu only responds to manual calls and UI navigation

func pause_game():
	if is_paused:
		return
		
	is_paused = true
	get_tree().paused = true
	visible = true
	pause_panel.visible = true
	settings_panel.visible = false
	
	# Focus the resume button for keyboard navigation
	$PausePanel/PauseContainer/PauseButtons/ResumeButton.grab_focus()
	
	print("Game paused")

func resume_game():
	if not is_paused:
		return
		
	is_paused = false
	get_tree().paused = false
	visible = false
	print("Game resumed")

func _on_resume_button_pressed():
	resume_game()

func _on_restart_button_pressed():
	print("Restarting level...")
	# Resume first to allow scene change
	is_paused = false
	get_tree().paused = false
	
	# Restart the current level
	get_tree().change_scene_to_file(current_level_scene)

func _on_settings_button_pressed():
	print("Opening pause menu settings...")
	pause_panel.visible = false
	settings_panel.visible = true
	
	# Focus the volume slider when opening settings
	volume_slider.grab_focus()

func _on_main_menu_button_pressed():
	print("Returning to main menu...")
	# Resume first to allow scene change
	is_paused = false
	get_tree().paused = false
	
	# Go to main menu
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_volume_slider_value_changed(value: float):
	# Convert linear volume (0-100) to decibels
	var volume_db = linear_to_db(value / 100.0)
	var master_bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus, volume_db)
	print("Volume set to: ", value, "%")

func _on_fullscreen_checkbox_toggled(toggled_on: bool):
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		print("Fullscreen enabled")
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		print("Windowed mode enabled")

func _on_back_button_pressed():
	_close_settings()

func _close_settings():
	print("Closing pause menu settings...")
	settings_panel.visible = false
	pause_panel.visible = true
	
	# Focus the resume button again
	$PausePanel/PauseContainer/PauseButtons/ResumeButton.grab_focus()

# Public method for other scripts to pause the game
func trigger_pause():
	pause_game()

# Public method to check if game is paused
func get_is_paused() -> bool:
	return is_paused