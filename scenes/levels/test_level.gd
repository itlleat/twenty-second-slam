extends Node2D

var enemy_scene = load("res://scenes/enemies/enemy.tscn")  # Changed to load() instead of preload()
var last_enemy_position = Vector2(700, 475)
var respawn_timer: Timer

func _ready():
	print("TestLevel _ready() started")
	print("Enemy scene loaded: ", enemy_scene != null)
	
	# Position the player
	# $Player.position = Vector2(512, 300)  # Start position in the middle and above ground
	
	# Set up respawn timer - COMMENTED OUT
	# respawn_timer = Timer.new()
	# respawn_timer.one_shot = true
	# respawn_timer.wait_time = 1
	# respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	# add_child(respawn_timer)
	
	# Connect to GameManager signals
	GameManager.game_started.connect(_on_game_started)
	GameManager.game_ended.connect(_on_game_ended)
	
	# print("About to spawn initial enemy")
	# Spawn initial enemy - COMMENTED OUT
	# spawn_enemy()
	
	# Start the game
	GameManager.start_game()
	
	# Add some test damage for testing
	await get_tree().create_timer(2.0).timeout
	print("Adding test damage...")
	GameManager.add_damage(10)  # Test scoring
	
	print("TestLevel _ready() finished")

func spawn_enemy():
	print("Attempting to spawn enemy...")
	if enemy_scene:
		var enemy = enemy_scene.instantiate()
		if enemy:
			print("Enemy instance created")
			add_child(enemy)
			# Use global_position because enemy emits its global position on death.
			# Setting local `position` to a global coordinate can place the
			# respawned enemy far from the intended spot if the parent has
			# any transform. Assign to `global_position` to preserve world coords.
			enemy.global_position = last_enemy_position
			# COMMENTED OUT - Signal connection for respawning
			# if enemy.has_signal("enemy_died"):
			#	enemy.enemy_died.connect(_on_enemy_died)
			# else:
			#	print("Warning: enemy instance has no 'enemy_died' signal")
			print("Enemy spawned at global position: ", enemy.global_position)
		else:
			print("Failed to instantiate enemy")
	else:
		print("Failed to load enemy scene")

func _on_game_started():
	"""Called when GameManager starts the game"""
	print("TestLevel: Game started")
	# spawn_enemy()  # COMMENTED OUT - no auto enemy spawning

func _on_game_ended(final_score: int):
	"""Called when GameManager ends the game"""
	print("TestLevel: Game ended with score: ", final_score)
	# Stop spawning enemies
	if respawn_timer:
		respawn_timer.stop()
	# Transition to game over screen
	get_tree().change_scene_to_file("res://scenes/ui/game_over.tscn")

# COMMENTED OUT - Enemy respawn functions
# func _on_enemy_died(enemy_pos):
#	print("Enemy death signal received at position: ", enemy_pos)
#	last_enemy_position = enemy_pos  # Store position for respawn
#	respawn_timer.start()

# func _on_respawn_timer_timeout():
#	print("Timer timeout - spawning enemy at position: ", last_enemy_position)
#	spawn_enemy()
