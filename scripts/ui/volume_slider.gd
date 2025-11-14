extends HSlider

# Volume slider controller script
# Handles volume adjustment and audio bus management

func _ready():
	# Initialize with current master volume
	var master_bus = AudioServer.get_bus_index("Master")
	var current_volume_db = AudioServer.get_bus_volume_db(master_bus)
	var current_volume_linear = db_to_linear(current_volume_db)
	value = current_volume_linear * 100.0
	
	# Connect the value_changed signal if not already connected
	if not value_changed.is_connected(_on_value_changed):
		value_changed.connect(_on_value_changed)

func _on_value_changed(new_value: float):
	# Convert slider value (0-100) to decibels
	var volume_db = linear_to_db(new_value / 100.0)
	
	# Apply to master bus
	var master_bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus, volume_db)
	
	# Optional: Save to settings manager if available
	if SettingsManager and SettingsManager.has_method("set_volume"):
		SettingsManager.set_volume(new_value / 100.0)
	
	print("Volume adjusted to: ", new_value, "% (", volume_db, " dB)")