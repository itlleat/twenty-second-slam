extends Control

# Main menu controller script
# Handles navigation between menu states and basic settings

@onready var settings_panel = $UI/SettingsPanel
@onready var volume_slider = $UI/SettingsPanel/SettingsContainer/VolumeContainer/VolumeSlider
@onready var fullscreen_checkbox = $UI/SettingsPanel/SettingsContainer/FullscreenCheckbox

func _ready():
	# Initialize settings with current values
	_load_settings()
	
	# Ensure settings panel is hidden initially
	settings_panel.visible = false
	
	# Focus the start button initially - wait one frame for UI to be ready
	call_deferred("_set_initial_focus")

func _set_initial_focus():
	$MainContainer/MenuButtons/StartButton.grab_focus()

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

func _on_start_button_pressed():
	print("Starting game...")
	# Change to the game scene
	get_tree().change_scene_to_file("res://test_level.tscn")

func _on_leaderboards_button_pressed():
	print("Opening leaderboards...")
	# TODO: Implement leaderboards scene
	# For now, just show a placeholder message
	_show_placeholder_message("Leaderboards coming soon!")

func _on_settings_button_pressed():
	print("Opening settings...")
	settings_panel.visible = true
	
	# Focus the volume slider when opening settings
	volume_slider.grab_focus()

func _on_exit_button_pressed():
	print("Exiting game...")
	get_tree().quit()

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
	print("Closing settings...")
	settings_panel.visible = false
	
	# Return focus to the settings button
	$MainContainer/MenuButtons/SettingsButton.grab_focus()

func _show_placeholder_message(message: String):
	# Simple placeholder message system
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(_on_dialog_closed.bind(dialog))

func _on_dialog_closed(dialog):
	dialog.queue_free()

# Handle input for quick navigation
func _input(event):
	if event.is_action_pressed("ui_cancel") and settings_panel.visible:
		_on_back_button_pressed()
