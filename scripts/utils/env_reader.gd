# Environment file reader for Godot
extends RefCounted
class_name EnvReader

static func load_env_file(file_path: String = ".env") -> Dictionary:
	"""Load environment variables from .env file"""
	var env_vars = {}
	
	if not FileAccess.file_exists(file_path):
		print("EnvReader: .env file not found at: ", file_path)
		return env_vars
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("EnvReader: Could not open .env file")
		return env_vars
	
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		
		# Skip empty lines and comments
		if line.is_empty() or line.begins_with("#"):
			continue
			
		# Parse KEY=VALUE format
		if "=" in line:
			var parts = line.split("=", false, 1)
			if parts.size() >= 2:
				var key = parts[0].strip_edges()
				var value = parts[1].strip_edges()
				# Remove quotes if present
				if (value.begins_with('"') and value.ends_with('"')) or \
				   (value.begins_with("'") and value.ends_with("'")):
					value = value.substr(1, value.length() - 2)
				env_vars[key] = value
	
	file.close()
	return env_vars