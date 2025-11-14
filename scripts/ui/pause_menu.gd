extends Control

# Pause menu controller script
# Handles pause menu functionality and settings

@onready var pause_panel = $PausePanel
@onready var settings_panel = $SettingsPanel
@onready var volume_slider = $SettingsPanel/SettingsContainer/VolumeContainer/VolumeSlider
@onready var fullscreen_checkbox = $SettingsPanel/SettingsContainer/FullscreenCheckbox

# Button references
@onready var resume_button = $PausePanel/PauseContainer/PauseButtons/ResumeButton
@onready var restart_button = $PausePanel/PauseContainer/PauseButtons/RestartButton
@onready var settings_button = $PausePanel/PauseContainer/PauseButtons/SettingsButton
@onready var main_menu_button = $PausePanel/PauseContainer/PauseButtons/MainMenuButton

func _ready():
	# Initialize settings with current values
	_load_settings()
	
	# Ensure correct panel visibility
	pause_panel.visible = true
	settings_panel.visible = false
	
	# Focus the resume button initially
	resume_button.grab_focus()

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

func _on_resume_button_pressed():
	print("Resuming game...")
	get_tree().paused = false
	visible = false

func _on_restart_button_pressed():
	print("Restarting level...")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/levels/test_level.tscn")

func _on_settings_button_pressed():
	print("Opening pause settings...")
	pause_panel.visible = false
	settings_panel.visible = true
	
	# Focus the volume slider when opening settings
	volume_slider.grab_focus()

func _on_main_menu_button_pressed():
	print("Returning to main menu...")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

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
	print("Closing pause settings...")
	settings_panel.visible = false
	pause_panel.visible = true
	
	# Return focus to the settings button
	settings_button.grab_focus()

# Handle input for quick navigation
func _input(event):
	if event.is_action_pressed("ui_cancel") and settings_panel.visible:
		_on_back_button_pressed()
	elif event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		if visible:
			_on_resume_button_pressed()