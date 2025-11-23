extends CharacterBody2D
extends ChairThrowState
extends MissilePincerState	

signal enemy_died(enemy_position)

var current_state = null # Holds the current BossState Resource
var state_instances = {}
var state_names = ["Kiting", "Attacking", "SpinningRing", "TentacleAttack", "ChairThrow", "MissilePincer"]
var current_state_name = "Kiting"
var attack_timer = 0.0
var attack_cooldown = 3.0  # Time between attacks

var health = 10
var flash_duration = 0.1
var shake_duration = 0.2
var shake_intensity = 2.0
var is_flashing = false
var is_shaking = false
var flash_timer = 0.0
var shake_timer = 0.0
var original_position = Vector2.ZERO
@onready var enemy_body = $EnemyBody
var flash_overlay: ColorRect

# Boss kiting behavior
var player_ref: CharacterBody2D
var kite_distance = 250.0  # Distance to maintain from player
var move_speed = 150.0  # Boss movement speed
var attack_windup_distance = 150.0  # Distance at which boss prepares to attack

# Attack patterns
var enemy_small_scene = preload("res://scenes/enemies/enemy_small.tscn")
var enemy_tiny_scene = preload("res://scenes/enemies/enemy_tiny.tscn")
var chair_1_scene = preload("res://scenes/enemies/chair_1.tscn")
var chair_2_scene = preload("res://scenes/enemies/chair_2.tscn")
var desk_lamp_scene = preload("res://scenes/enemies/desk_lamp.tscn")
var ring_projectile_count = 8  # Number of projectiles in ring attack

# Chair throw attack
var chair_throw_timer = 0.0
var chair_throw_cooldown = 2.5  # Seconds between chair throws
var chair_speed = 400.0  # Speed of thrown chairs
var use_chair_2 = false  # Alternate between chair_1 and chair_2

# Missile pincer attack
var missile_pincer_timer = 0.0
var missile_pincer_cooldown = 4.0  # Seconds between missile volleys
var missiles_per_side = 16  # Number of missiles per side
var missile_speed = 350.0  # Speed of missiles
var missile_spawn_interval = 0.1  # Seconds between each missile spawn
var missile_homing_strength = 3.0  # How aggressively missiles track

# Spinning ring attack
var spinning_ring_projectiles = []  # Array to track active ring projectiles
var spinning_ring_radius = 150.0  # Distance from boss center (closer ring)
var spinning_ring_speed = 2.0  # Radians per second
var spinning_ring_angle = 0.0  # Current rotation angle
var ring_respawn_timers = []  # Individual respawn timers for each slot

# Inner ring attack (desk lamps) - actually the OUTER ring now
var inner_ring_projectiles = []  # Array to track active inner ring projectiles
var inner_ring_radius = 250.0  # Further out than outer ring
var inner_ring_speed = 2.5  # Slightly faster rotation
var inner_ring_angle = 0.0  # Current rotation angle (offset from outer ring)
var inner_ring_count = 12  # Number of desk lamps in outer ring
var inner_ring_respawn_timers = []  # Individual respawn timers for each slot

# Tentacle attack
var tentacle_count = 4  # Number of tentacles
var tentacle_length = 5  # Number of enemy_tiny per tentacle
var tentacles = []  # Array of arrays - each tentacle is an array of enemy_tiny
var tentacle_angles = []  # Current angle of each tentacle
var tentacle_extend_speed = 200.0  # How fast tentacles extend
var tentacle_is_extending = []  # Track if tentacle is extending or retracting
var tentacle_base_distance = 50.0  # Starting distance from boss
var tentacle_max_distance = 300.0  # Maximum extension
var tentacle_spawn_timer = 0.0  # Timer for automatic tentacle spawning
var tentacle_spawn_delay = 4.0  # Seconds before tentacles appear
var tentacles_spawned = false  # Track if tentacles have been spawned

func _ready():
	enemy_body = $EnemyBody
	flash_overlay = $FlashOverlay
	original_position = enemy_body.position
	
	# Ensure flash overlay starts invisible
	flash_overlay.visible = false
	
	# Connect the hit detection signal
	$HitBox.area_entered.connect(_on_hit_box_area_entered)
	
	# Find player reference
	call_deferred("_find_player")
	
	# Initialize spinning ring arrays
	for i in range(ring_projectile_count):
		spinning_ring_projectiles.append(null)
		ring_respawn_timers.append(0.0)
	
	# Don't initialize tentacle arrays - tentacles disabled in favor of missiles
	
	# Start spinning ring attack
	call_deferred("start_spinning_ring")

func _find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
	else:
		# Fallback: search by name
		player_ref = get_node_or_null("../Player")

func change_state(new_state_name: String):
	if current_state:
		current_state.exit(self)
	current_state_name = new_state_name
	current_state = state_instances.get(new_state_name, null)
	if current_state:
		current_state.enter(self)
	else:
		print("WARNING: State ", new_state_name, " not found!")

func _physics_process(_delta):
	if player_ref:
		# Modular state system
		if current_state:
			current_state.update(self, get_physics_process_delta_time())
		move_and_slide()

func handle_kiting_state():
	kite_from_player()
	
	# Check if it's time to attack
	attack_timer += get_physics_process_delta_time()
	if attack_timer >= attack_cooldown:
		start_attack()

func handle_attacking_state():
	# Stop moving during attack
	velocity = Vector2.ZERO

func start_attack():
	print("Boss starting ring attack!")
	attack_timer = 0.0
	# Perform ring projectile attack
	spawn_ring_projectiles()
	# Return to kiting after a brief moment
	await get_tree().create_timer(0.3).timeout
	change_state("Kiting")

func spawn_ring_projectiles():
	# Fibonacci spiral pattern using golden angle
	var golden_angle = PI * (3.0 - sqrt(5.0))  # ~137.5 degrees in radians
	
	for i in range(ring_projectile_count):
		# Fibonacci spiral: distance grows with square root, angle uses golden ratio
		var distance = sqrt(float(i)) * 50.0  # Distance from center
		var angle = i * golden_angle
		var direction = Vector2(cos(angle), sin(angle))
		
		# Spawn enemy_small projectile
		var projectile = enemy_small_scene.instantiate()
		
		# IMPORTANT: Set projectile mode BEFORE adding to scene
		# This prevents _ready() from setting up normal enemy behavior
		projectile.is_projectile_mode = true
		
		get_parent().add_child(projectile)
		projectile.global_position = global_position + direction * distance
		
		# Set projectile velocity (move outward from spawn position)
		projectile.velocity = direction * 300.0
		
		# Enable flying mode after everything is set up
		if projectile.has_method("set_projectile_mode"):
			projectile.set_projectile_mode(true)
	
	print("Spawned ", ring_projectile_count, " projectiles in fibonacci spiral pattern")

func kite_from_player():
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	var direction_from_player = (global_position - player_ref.global_position).normalized()
	
	# Check if player is attacking (punching, kicking, heavy punching)
	var player_is_attacking = false
	if player_ref.has_method("get") and "current_state" in player_ref:
		var player_state = player_ref.current_state
		# PlayerState: PUNCHING=4, HEAVY_PUNCHING=5, KICKING=6
		if player_state in [4, 5, 6]:
			player_is_attacking = true
	
	if player_is_attacking and distance_to_player < 300:
		# Player is attacking nearby - dodge away aggressively
		velocity = direction_from_player * move_speed * 1.5
	elif distance_to_player < kite_distance:
		# Player too close - back away
		velocity = direction_from_player * move_speed
	elif distance_to_player > kite_distance + 100:
		# Player too far - move closer slowly
		velocity = -direction_from_player * move_speed * 0.5
	else:
		# At good distance - strafe around player
		var perpendicular = Vector2(-direction_from_player.y, direction_from_player.x)
		velocity = perpendicular * move_speed * 0.7

func _process(delta):
	if is_flashing:
		flash_timer -= delta
		if flash_timer <= 0:
			is_flashing = false
			if flash_overlay:
				flash_overlay.visible = false

	if is_shaking:
		shake_timer -= delta
		if shake_timer <= 0:
			is_shaking = false
			enemy_body.position = original_position
			if flash_overlay:
				flash_overlay.position = enemy_body.position
		else:
			# Random shake offset
			var offset = Vector2(
				randf_range(-1, 1) * shake_intensity,
				randf_range(-1, 1) * shake_intensity
			)
			enemy_body.position = original_position + offset
			if flash_overlay:
				flash_overlay.position = enemy_body.position

func take_hit(damage: int = 1):
	health -= damage
	print("Enemy took hit! Health now: ", health)
	
	# Report damage to GameManager (damage per hit)
	GameManager.add_damage(damage)

	# Start flash effect (overlay so we don't rely on original_color)
	is_flashing = true
	flash_timer = flash_duration
	if flash_overlay:
		flash_overlay.visible = true

	# Start shake effect
	is_shaking = true
	shake_timer = shake_duration

	if health <= 0:
		print("Enemy dying at position: ", global_position)
		# Report bonus damage for killing enemy
		GameManager.add_damage(5)  # 5 bonus damage for killing enemy
		# emit_signal("enemy_died", global_position)  # Signal death with position - COMMENTED OUT
		queue_free()  # Remove enemy when health reaches 0

func _on_hit_box_area_entered(area):
	if area.name == "PunchHitBox":
		print("Enemy hit by punch!")
		take_hit()

func start_spinning_ring():
	print("Boss starting spinning ring attack!")
	change_state("SpinningRing")

func handle_spinning_ring_state():
	# Continue kiting while maintaining the ring
	kite_from_player()
	
	# Check if it's time to spawn tentacles (DISABLED - using missiles instead)
	# if not tentacles_spawned:
	# 	tentacle_spawn_timer += get_physics_process_delta_time()
	# 	if tentacle_spawn_timer >= tentacle_spawn_delay:
	# 		tentacles_spawned = true
	# 		# Spawn tentacles while staying in spinning ring state
	# 		for i in range(tentacle_count):
	# 			spawn_tentacle(i)
	
	# Update ring rotation
	spinning_ring_angle += spinning_ring_speed * get_physics_process_delta_time()
	inner_ring_angle += inner_ring_speed * get_physics_process_delta_time()
	
	# Update outer ring projectile positions (only if arrays are initialized)
	if spinning_ring_projectiles.size() > 0:
		for i in range(ring_projectile_count):
			var projectile = spinning_ring_projectiles[i]
			
			# Check if projectile exists and is still valid
			if projectile and is_instance_valid(projectile):
				# Update position to orbit around boss
				var angle = spinning_ring_angle + (TAU / ring_projectile_count) * i
				var offset = Vector2(cos(angle), sin(angle)) * spinning_ring_radius
				projectile.global_position = global_position + offset
			else:
				# Projectile was destroyed, increment respawn timer
				if spinning_ring_projectiles[i] != null:
					# Just got destroyed, start timer
					spinning_ring_projectiles[i] = null
					ring_respawn_timers[i] = 3.0
					print("Ring projectile ", i, " destroyed, respawning in 3 seconds")
				
				# Count down respawn timer
				if ring_respawn_timers[i] > 0:
					ring_respawn_timers[i] -= get_physics_process_delta_time()
					if ring_respawn_timers[i] <= 0:
						# Time to respawn
						spawn_ring_projectile(i)
						print("Respawned ring projectile ", i)
	
	# Update inner ring projectile positions (only if arrays are initialized)
	if inner_ring_projectiles.size() > 0:
		for i in range(inner_ring_count):
			var projectile = inner_ring_projectiles[i]
			
			# Check if projectile exists and is still valid
			if projectile and is_instance_valid(projectile):
				# Update position to orbit around boss
				var angle = inner_ring_angle + (TAU / inner_ring_count) * i
				var offset = Vector2(cos(angle), sin(angle)) * inner_ring_radius
				projectile.global_position = global_position + offset
			else:
				# Projectile was destroyed, increment respawn timer
				if inner_ring_projectiles[i] != null:
					# Just got destroyed, start timer
					inner_ring_projectiles[i] = null
					inner_ring_respawn_timers[i] = 3.0
					print("Inner ring projectile ", i, " destroyed, respawning in 3 seconds")
				
				# Count down respawn timer
				if inner_ring_respawn_timers[i] > 0:
					inner_ring_respawn_timers[i] -= get_physics_process_delta_time()
					if inner_ring_respawn_timers[i] <= 0:
						# Time to respawn
						spawn_inner_ring_projectile(i)
						print("Respawned inner ring projectile ", i)
	
	# Update tentacles if they're spawned (DISABLED - using missiles instead)
	# if tentacles_spawned:
	# 	update_tentacles()
	
	# Throw chairs intermittently
	chair_throw_timer += get_physics_process_delta_time()
	if chair_throw_timer >= chair_throw_cooldown:
		throw_chair_at_player()
		chair_throw_timer = 0.0
	
	# Launch missile pincer attack intermittently
	missile_pincer_timer += get_physics_process_delta_time()
	if missile_pincer_timer >= missile_pincer_cooldown:
		launch_missile_pincer()
		missile_pincer_timer = 0.0

func spawn_ring_projectile(index: int):
	var angle = spinning_ring_angle + (TAU / ring_projectile_count) * index
	var offset = Vector2(cos(angle), sin(angle)) * spinning_ring_radius
	
	# Spawn enemy_small
	var projectile = enemy_small_scene.instantiate()
	projectile.is_projectile_mode = true
	projectile.is_ring_mode = true  # New flag to disable physics entirely
	
	get_parent().add_child(projectile)
	projectile.global_position = global_position + offset
	projectile.velocity = Vector2.ZERO  # No velocity for orbiting projectiles
	
	# Store reference
	spinning_ring_projectiles[index] = projectile
	ring_respawn_timers[index] = 0.0

func spawn_inner_ring_projectile(index: int):
	var angle = inner_ring_angle + (TAU / inner_ring_count) * index
	var offset = Vector2(cos(angle), sin(angle)) * inner_ring_radius
	
	# Spawn desk_lamp
	var projectile = desk_lamp_scene.instantiate()
	projectile.is_projectile_mode = true
	projectile.is_ring_mode = true  # New flag to disable physics entirely
	
	get_parent().add_child(projectile)
	projectile.global_position = global_position + offset
	projectile.velocity = Vector2.ZERO  # No velocity for orbiting projectiles
	
	# Store reference
	inner_ring_projectiles[index] = projectile
	inner_ring_respawn_timers[index] = 0.0

func handle_tentacle_attack_state():
	# Continue kiting while tentacles are active
	kite_from_player()
	update_tentacles()

func update_tentacles():
	# Update each tentacle
	for i in range(tentacle_count):
		var tentacle = tentacles[i]
		var angle = tentacle_angles[i]
		var is_extending = tentacle_is_extending[i]
		
		# Create tentacle if empty
		if tentacle.size() == 0:
			spawn_tentacle(i)
			continue
		
		# Update tentacle positions
		for j in range(tentacle.size()):
			var segment = tentacle[j]
			
			# Check if segment still exists
			if not segment or not is_instance_valid(segment):
				# Segment destroyed - respawn entire tentacle after delay
				tentacle.clear()
				await get_tree().create_timer(4.0).timeout
				spawn_tentacle(i)
				break
			
			# Calculate position along tentacle
			var distance_from_boss = tentacle_base_distance + (j * 30.0)  # 30 units between segments
			if is_extending:
				distance_from_boss = min(distance_from_boss, tentacle_max_distance)
			
			var direction = Vector2(cos(angle), sin(angle))
			segment.global_position = global_position + direction * distance_from_boss
		
		# Rotate tentacles slowly
		tentacle_angles[i] += 0.5 * get_physics_process_delta_time()

func spawn_tentacle(index: int):
	print("Spawning tentacle ", index)
	var angle = tentacle_angles[index]
	var tentacle = []
	
	for j in range(tentacle_length):
		var segment = enemy_tiny_scene.instantiate()
		segment.health = 3  # Less health for tentacle segments
		
		get_parent().add_child(segment)
		
		# Initial position
		var distance = tentacle_base_distance + (j * 30.0)
		var direction = Vector2(cos(angle), sin(angle))
		segment.global_position = global_position + direction * distance
		
		tentacle.append(segment)
	
	tentacles[index] = tentacle
	print("Spawned tentacle ", index, " with ", tentacle_length, " segments")

func start_tentacle_attack():
	print("Boss starting tentacle attack!")
	change_state("TentacleAttack")
	# Spawn all tentacles
	for i in range(tentacle_count):
		spawn_tentacle(i)

func throw_chair_at_player():
	if not player_ref:
		return
	
	print("Boss throwing chair at player!")
	
	# Calculate direction to player
	var direction_to_player = (player_ref.global_position - global_position).normalized()
	
	# Alternate between chair_1 and chair_2
	var chair_scene = chair_2_scene if use_chair_2 else chair_1_scene
	use_chair_2 = not use_chair_2  # Toggle for next throw
	
	# Spawn chair projectile
	var chair = chair_scene.instantiate()
	chair.is_projectile_mode = true
	chair.is_homing = true  # Enable homing behavior
	chair.homing_strength = 2.0  # Moderate tracking (adjust higher for tighter tracking)
	
	get_parent().add_child(chair)
	chair.global_position = global_position
	
	# Set velocity toward player
	chair.velocity = direction_to_player * chair_speed
	
	# Enable projectile mode
	if chair.has_method("set_projectile_mode"):
		chair.set_projectile_mode(true)

func handle_chair_throw_state():
	# Continue kiting while throwing chairs
	kite_from_player()
	
	# Throw chairs intermittently
	chair_throw_timer += get_physics_process_delta_time()
	if chair_throw_timer >= chair_throw_cooldown:
		throw_chair_at_player()
		chair_throw_timer = 0.0

func launch_missile_pincer():
	if not player_ref:
		return
	
	print("Boss launching missile pincer attack!")
	
	# Spawn missiles from left and right sides rapidly
	for i in range(missiles_per_side):
		# Pass the index to spawn function for spread calculation
		get_tree().create_timer(i * missile_spawn_interval).timeout.connect(
			func(): spawn_missile_from_side(true, i)
		)
		get_tree().create_timer(i * missile_spawn_interval).timeout.connect(
			func(): spawn_missile_from_side(false, i)
		)

func spawn_missile_from_side(from_left: bool, missile_index: int = 0):
	if not player_ref:
		return
	
	print("Attempting to spawn missile from ", "left" if from_left else "right", " side")
	
	# Calculate direction to player
	var direction_to_player = (player_ref.global_position - global_position).normalized()
	
	# Get perpendicular direction (90 degrees rotated)
	# Perpendicular vector: if direction is (x, y), perpendicular is (-y, x) for left or (y, -x) for right
	var perpendicular = Vector2(-direction_to_player.y, direction_to_player.x) if from_left else Vector2(direction_to_player.y, -direction_to_player.x)
	
	# Calculate spread angle based on missile index
	# Missiles spread out initially (max spread at middle indices)
	var max_spread_angle = 25.0  # degrees
	var progress = float(missile_index) / float(missiles_per_side - 1)  # 0 to 1
	# Use sin curve to spread at middle, converge at ends
	var spread_factor = sin(progress * PI)  # Peaks at 0.5 (middle)
	var spread_angle = spread_factor * max_spread_angle
	
	# Apply spread to perpendicular direction
	# Convert to radians and rotate
	var spread_radians = deg_to_rad(spread_angle)
	if not from_left:
		spread_radians = -spread_radians  # Mirror spread for right side
	
	var spread_direction = perpendicular.rotated(spread_radians)
	
	# Spawn position offset from boss
	var side_offset = perpendicular * 100.0
	var spawn_pos = global_position + side_offset
	
	# Missiles start by moving in spread direction
	var initial_direction = spread_direction
	
	# Spawn missile
	var missile = enemy_tiny_scene.instantiate()
	missile.is_missile_mode = true
	missile.is_homing = true
	missile.homing_strength = missile_homing_strength
	
	print("Created missile instance, adding to scene...")
	get_parent().add_child(missile)
	missile.global_position = spawn_pos
	
	# Set initial velocity moving in spread direction
	missile.velocity = initial_direction * missile_speed
	
	# Enable missile mode
	if missile.has_method("set_missile_mode"):
		missile.set_missile_mode(true)
		print("Set missile mode enabled")
	else:
		print("WARNING: Missile doesn't have set_missile_mode method!")
	
	print("Spawned missile at position: ", spawn_pos, " with velocity: ", missile.velocity)

func handle_missile_pincer_state():
	# Continue kiting while missiles are active
	kite_from_player()

