extends Node

# Global Settings Manager - Singleton for handling all game settings
# This ensures consistent settings behavior across all menus

signal volume_changed(new_volume: float)
signal fullscreen_changed(is_fullscreen: bool)

var current_volume: float = 100.0
var is_fullscreen: bool = false

func _ready():
	# Load settings on startup
	_load_initial_settings()

func _load_initial_settings():
	# Load volume setting from audio system
	var master_bus = AudioServer.get_bus_index("Master")
	var volume_db = AudioServer.get_bus_volume_db(master_bus)
	var volume_linear = db_to_linear(volume_db)
	current_volume = volume_linear * 100.0
	
	# Load fullscreen setting
	is_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

func set_volume(volume_percent: float):
	# Clamp volume to valid range
	volume_percent = clamp(volume_percent, 0.0, 100.0)
	current_volume = volume_percent
	
	# Apply to audio system
	var volume_db = linear_to_db(volume_percent / 100.0)
	var master_bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus, volume_db)
	
	# Notify all listeners
	volume_changed.emit(current_volume)
	
	print("Settings Manager: Volume set to ", volume_percent, "%")

func get_volume() -> float:
	return current_volume

func set_fullscreen(fullscreen: bool):
	is_fullscreen = fullscreen
	
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		print("Settings Manager: Fullscreen enabled")
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		print("Settings Manager: Windowed mode enabled")
	
	# Notify all listeners
	fullscreen_changed.emit(is_fullscreen)

func get_fullscreen() -> bool:
	return is_fullscreen

func toggle_fullscreen():
	set_fullscreen(not is_fullscreen)

# Save settings to file (can be implemented later)
func save_settings():
	# TODO: Save to user://settings.cfg or similar
	pass

# Load settings from file (can be implemented later)  
func load_settings():
	# TODO: Load from user://settings.cfg or similar
	pass