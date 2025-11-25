extends CharacterBody2D

enum PlayerState {
	IDLE,
	WALKING,
	WALK_UP,
	WALK_DOWN,
	PUNCHING,
	HEAVY_PUNCHING,
	KICKING,
	DASHING
}

var current_state = PlayerState.IDLE
var move_speed = 600.0
var dash_force = 1800.0
var dash_duration = 0.4
var punch_duration = 0.2  # Duration of punch animation/action
var punch_hitbox_start = 0.03  # When hitbox becomes active
var punch_hitbox_end = 0.18  # When hitbox deactivates
var heavy_punch_duration = 0.3  # Heavy punch is much slower
var heavy_punch_hitbox_start = 0.15  # Delayed startup
var heavy_punch_hitbox_end = 0.3  # Longer active window
var kick_duration = 0.3  # Kicks are slightly slower than punches
var kick_hitbox_start = 0.08  # When kick hitbox becomes active
var kick_hitbox_end = 0.25  # When kick hitbox deactivates
var gravity = 980.0
var punch_timer = 0.0
var heavy_punch_timer = 0.0
var kick_timer = 0.0
var kick_has_hit = false  # Track if kick has already hit this attack
var heavy_punch_has_hit = false  # Track if heavy punch has already hit this attack
var dash_timer = 0.0
var facing_right = true

var punch_area: Area2D
var punch_rect: ColorRect
var heavy_punch_area: Area2D
var heavy_punch_rect: ColorRect
var kick_area: Area2D
var kick_rect: ColorRect
var dash_area: Area2D
var dash_rect: ColorRect
var player_body: ColorRect
var player_sprite: AnimatedSprite2D
var player_camera: Camera2D
var can_move_vertically = false
var dash_has_hit = false  # Track if dash has already hit this attack

func _ready():
	# Get the existing camera from the scene
	if has_node("Camera2D"):
		player_camera = $Camera2D
		print("Using existing camera from scene")
	else:
		# Create and add camera if it doesn't exist
		var camera = Camera2D.new()
		camera.enabled = true
		
		# Add smoothing for smoother camera movement
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 5.0
		
		# Set zoom level (adjust as needed)
		camera.zoom = Vector2(1.2, 1.2)  # Slight zoom in
		
		# Set camera limits to prevent going outside level bounds
		camera.limit_left = 0
		camera.limit_right = 1920
		camera.limit_top = 0
		camera.limit_bottom = 1080
		
		add_child(camera)
		player_camera = camera  # Store reference for zoom effects
		print("Created new camera")

	punch_area = $PunchHitBox
	punch_rect = $PunchHitBox/PunchRect
	punch_area.area_entered.connect(_on_punch_hit_box_area_entered)
	
	# Get heavy punch hitbox
	if has_node("HeavyPunchHitBox"):
		heavy_punch_area = $HeavyPunchHitBox
		heavy_punch_rect = $HeavyPunchHitBox/HeavyPunchRect
		heavy_punch_area.area_entered.connect(_on_heavy_punch_hit_box_area_entered)
	
	# Get kick hitbox if it exists, otherwise create it later
	if has_node("KickHitBox"):
		kick_area = $KickHitBox
		kick_rect = $KickHitBox/KickRect
	
	# Get dash hitbox
	if has_node("DashHitBox"):
		dash_area = $DashHitBox
		dash_rect = $DashHitBox/DashRect
	
	player_body = $PlayerBody
	player_sprite = $PlayerSprite
	
	# Force sprite to be centered and at consistent position
	player_sprite.centered = true
	player_sprite.offset = Vector2.ZERO
	player_sprite.position = Vector2(0, -31)  # Adjust Y to align with collision shape
	
	# Start with idle animation
	player_sprite.play("idle")
	
	# Start with punch hitbox disabled
	punch_area.visible = false
	punch_area.monitoring = false
	punch_area.monitorable = false
	
	# Start with heavy punch hitbox disabled
	if heavy_punch_area:
		heavy_punch_area.visible = false
		heavy_punch_area.monitoring = false
		heavy_punch_area.monitorable = false
	
	# Start with kick hitbox disabled
	if kick_area:
		kick_area.visible = false
		kick_area.monitoring = false
		kick_area.monitorable = false
	
	# Start with dash hitbox disabled
	if dash_area:
		dash_area.visible = false
		dash_area.monitoring = false
		dash_area.monitorable = false
	
	# Always ensure punch hitbox starts hidden
	punch_area.visible = false
	punch_area.process_mode = Node.PROCESS_MODE_INHERIT  # Ensure it can be shown/hidden
	
	# Create collision shape if it doesn't exist
	# if !has_node("CollisionShape2D"):
	# 	var collision = CollisionShape2D.new()
	# 	var shape = RectangleShape2D.new()
	# 	# Collision shape size for the player should be set in the editor
	# 	collision.shape = shape
	# 	collision.position = Vector2(0, -32)  # Center the collision shape
	# 	add_child(collision)

func _physics_process(delta):
	# Handle punch input - can cancel dash
	if Input.is_action_just_pressed("punch"):
		if current_state not in [PlayerState.PUNCHING, PlayerState.HEAVY_PUNCHING, PlayerState.KICKING]:
			start_punch()
	
	# Handle heavy punch input - can cancel dash
	if Input.is_action_just_pressed("heavy_punch"):
		if current_state not in [PlayerState.PUNCHING, PlayerState.HEAVY_PUNCHING, PlayerState.KICKING]:
			start_heavy_punch()
	
	# Handle kick input - can cancel dash
	if Input.is_action_just_pressed("kick"):
		if current_state not in [PlayerState.PUNCHING, PlayerState.HEAVY_PUNCHING, PlayerState.KICKING]:
			start_kick()
	
	# Handle dash input - only works in movement areas and not while attacking
	if Input.is_action_just_pressed("jump") and can_move_vertically:
		if current_state not in [PlayerState.PUNCHING, PlayerState.KICKING]:
			start_dash()
	
	match current_state:
		PlayerState.IDLE:
			handle_idle_state(delta)
		PlayerState.WALKING:
			handle_walking_state(delta)
		PlayerState.WALK_UP:
			handle_walk_up_state(delta)
		PlayerState.WALK_DOWN:
			handle_walk_down_state(delta)
		PlayerState.PUNCHING:
			handle_punching_state(delta)
		PlayerState.HEAVY_PUNCHING:
			handle_heavy_punching_state(delta)
		PlayerState.KICKING:
			handle_kicking_state(delta)
		PlayerState.DASHING:
			handle_dashing_state(delta)
	
	# No gravity - all movement is contained within free movement area
	
	move_and_slide()
	update_state()

func handle_idle_state(_delta):
	# Only allow movement in free movement area
	if can_move_vertically:
		velocity = Vector2.ZERO
		handle_movement_input()
	else:
		# Outside free movement area - no movement allowed
		velocity = Vector2.ZERO

func handle_walking_state(_delta):
	# Only allow movement in free movement area
	if can_move_vertically:
		handle_movement_input()
	else:
		# Outside free movement area - stop moving
		velocity = Vector2.ZERO
		current_state = PlayerState.IDLE

func handle_walk_up_state(_delta):
	# Same as walking state - free movement in all directions
	handle_movement_input()

func handle_walk_down_state(_delta):
	# Same as walking state - free movement in all directions
	handle_movement_input()

func handle_punching_state(delta):
	punch_timer -= delta
	
	# Stop all movement while punching
	velocity = Vector2.ZERO
	
	# Manage hitbox visibility based on animation timing
	var time_in_punch = punch_duration - punch_timer
	if time_in_punch >= punch_hitbox_start and time_in_punch <= punch_hitbox_end:
		# Hitbox active during this window
		punch_area.visible = true
		punch_area.monitoring = true
		punch_area.monitorable = true
	else:
		# Hitbox inactive
		punch_area.visible = false
		punch_area.monitoring = false
		punch_area.monitorable = false
	
	# End punch when timer expires
	if punch_timer <= 0:
		stop_punch()
		current_state = PlayerState.IDLE

func handle_kicking_state(delta):
	kick_timer -= delta
	
	# Stop all movement while kicking
	velocity = Vector2.ZERO
	
	# Manage kick hitbox visibility based on animation timing (EXACTLY like punch)
	var time_in_kick = kick_duration - kick_timer
	if time_in_kick >= kick_hitbox_start and time_in_kick <= kick_hitbox_end:
		# Hitbox active during this window
		kick_area.visible = true
		kick_area.monitoring = true
		kick_area.monitorable = true
		
		# WORKAROUND: Manually check for overlaps and call enemy hit detection
		# For some reason area_entered signal doesn't fire for kick
		if not kick_has_hit:
			var overlapping = kick_area.get_overlapping_areas()
			for area in overlapping:
				if area.name == "HitBox":
					var enemy = area.get_parent()
					if enemy and enemy.has_method("take_hit"):
						enemy.take_hit(2)  # Kicks do 2 damage (punches do 1)
						kick_has_hit = true  # Mark that we've hit
						break
	else:
		# Hitbox inactive
		kick_area.visible = false
		kick_area.monitoring = false
		kick_area.monitorable = false
	
	# End kick when timer expires
	if kick_timer <= 0:
		stop_kick()
		current_state = PlayerState.IDLE

func handle_dashing_state(delta):
	dash_timer -= delta
	
	# Check for dash attack hits
	if dash_area and not dash_has_hit:
		var overlapping = dash_area.get_overlapping_areas()
		for area in overlapping:
			if area.name == "HitBox":
				var enemy = area.get_parent()
				if enemy and enemy.has_method("take_hit"):
					enemy.take_hit(1)  # Dash does 1 damage
					dash_has_hit = true  # Mark that we've hit
					break
	
	if dash_timer <= 0:
		# End dash and disable hitbox
		if dash_area:
			dash_area.monitoring = false
			dash_area.monitorable = false
		current_state = PlayerState.IDLE
		# Slow down after dash
		velocity.x *= 0.5
		if can_move_vertically:
			velocity.y *= 0.5
	# Don't handle input during dash - keep dash velocity



func handle_movement_input():
	# Only allow input when in free movement area
	if not can_move_vertically:
		return
	
	# Use a more direct approach to get input values
	var input_vector = Vector2.ZERO
	
	# Get keyboard input
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1.0
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1.0
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1.0
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1.0
	
	# Get joystick input (with lower deadzone for better responsiveness)
	var joy_vector = Vector2(
		Input.get_joy_axis(0, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	)
	
	# Apply custom deadzone for joystick (much lower than 0.5)
	var deadzone = 0.15
	if joy_vector.length() > deadzone:
		# Use joystick input if it's beyond deadzone
		input_vector = joy_vector
	
	# Normalize to ensure consistent movement speed in all directions
	if input_vector.length() > 0.0:
		if input_vector.length() > 1.0:
			input_vector = input_vector.normalized()
	
	# Apply movement
	velocity.x = input_vector.x * move_speed
	velocity.y = input_vector.y * move_speed
	
	# Update facing direction
	if input_vector.x != 0:
		facing_right = input_vector.x > 0

func start_dash():
	print("Starting dash!")
	current_state = PlayerState.DASHING
	dash_timer = dash_duration
	dash_has_hit = false  # Reset hit flag for new dash
	
	# Enable dash hitbox during dash
	if dash_area:
		dash_area.monitoring = true
		dash_area.monitorable = true
		dash_area.visible = false  # Keep invisible but active
	
	# Get current input for dash direction using the same method as movement
	var input_vector = Vector2.ZERO
	
	# Get keyboard input
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1.0
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1.0
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1.0
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1.0
	
	# Get joystick input
	var joy_vector = Vector2(
		Input.get_joy_axis(0, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	)
	
	var deadzone = 0.15
	if joy_vector.length() > deadzone:
		input_vector = joy_vector
	
	var dash_direction = Vector2.ZERO
	
	# Dash in any direction based on input
	if input_vector.length() > 0:
		dash_direction = input_vector.normalized()
		# Lock facing direction based on dash direction
		if abs(dash_direction.x) > 0.1:  # Only update facing if there's horizontal movement
			facing_right = dash_direction.x > 0
			player_sprite.flip_h = not facing_right
	else:
		# No input - dash in facing direction
		dash_direction = Vector2(1 if facing_right else -1, 0)
	
	velocity = dash_direction * dash_force
	print("Dashing in direction: ", dash_direction)

func start_punch():
	print("Starting punch!")
	
	# Lock facing direction based on current movement or last facing
	# This prevents the sprite from flipping mid-punch
	if abs(velocity.x) > 10:
		facing_right = velocity.x > 0
		player_sprite.flip_h = not facing_right
	
	current_state = PlayerState.PUNCHING
	punch_timer = punch_duration
	
	# Position punch hitbox based on facing direction
	var horizontal_offset := 40.0
	punch_area.position = Vector2(horizontal_offset if facing_right else -horizontal_offset, -40)
	
	# Hitbox starts disabled - will be enabled during animation window
	punch_area.visible = false
	punch_area.monitoring = false
	punch_area.monitorable = false

func stop_punch():
	# Disable hitbox when punch ends
	punch_area.visible = false
	punch_area.monitoring = false
	punch_area.monitorable = false

func start_heavy_punch():
	print("Starting heavy punch!")
	
	# Zoom out camera for dramatic effect
	if player_camera:
		player_camera.zoom = Vector2(1, 1)  #  zoomed out
		print("Camera zoom set to: ", player_camera.zoom)
	else:
		print("ERROR: player_camera is null!")
	
	# Lock facing direction
	if abs(velocity.x) > 10:
		facing_right = velocity.x > 0
		player_sprite.flip_h = not facing_right
	
	current_state = PlayerState.HEAVY_PUNCHING
	heavy_punch_timer = heavy_punch_duration
	heavy_punch_has_hit = false  # Reset hit flag for new heavy punch
	
	# Position heavy punch hitbox
	var horizontal_offset := 50.0  # Slightly longer range
	heavy_punch_area.position = Vector2(horizontal_offset if facing_right else -horizontal_offset, -40)
	
	# Hitbox starts disabled
	heavy_punch_area.visible = false
	heavy_punch_area.monitoring = false
	heavy_punch_area.monitorable = false

func stop_heavy_punch():
	# Zoom camera back to normal with smooth tween
	if player_camera:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_property(player_camera, "zoom", Vector2(1.3, 1.3), 0.3)
	
	# Disable hitbox when heavy punch ends
	heavy_punch_area.visible = false
	heavy_punch_area.monitoring = false
	heavy_punch_area.monitorable = false

func handle_heavy_punching_state(delta):
	heavy_punch_timer -= delta

	# Stop all movement while heavy punching
	velocity = Vector2.ZERO

	# Manage hitbox visibility based on animation timing
	var time_in_punch = heavy_punch_duration - heavy_punch_timer
	if time_in_punch >= heavy_punch_hitbox_start and time_in_punch <= heavy_punch_hitbox_end:
		# Hitbox active during this window
		heavy_punch_area.visible = true
		heavy_punch_area.monitoring = true
		heavy_punch_area.monitorable = true

		# Heavy punch hits ALL enemies on screen for 5 damage
		if not heavy_punch_has_hit:
			# Play heavy punch SFX
			var audio_manager = get_node_or_null("../GlobalAudioManager")
			if audio_manager:
				audio_manager.play_heavy_punch_sfx()
			# Get all enemies in the scene
			var enemies = get_tree().get_nodes_in_group("enemies")
			if enemies.size() == 0:
				# Fallback: search for enemies by name pattern
				var parent = get_parent()
				if parent:
					for node in parent.get_children():
						if node.has_method("take_hit") and node != self:
							enemies.append(node)
			# Damage all enemies
			for enemy in enemies:
				if enemy and enemy.has_method("take_hit"):
					enemy.take_hit(5)  # Heavy punch does 5 damage to ALL enemies
			if enemies.size() > 0:
				print("Heavy punch hit ", enemies.size(), " enemies for 5 damage each!")
			heavy_punch_has_hit = true  # Only trigger once per heavy punch
	else:
		# Hitbox inactive
		heavy_punch_area.visible = false
		heavy_punch_area.monitoring = false
		heavy_punch_area.monitorable = false

	# End heavy punch when timer expires
	if heavy_punch_timer <= 0:
		stop_heavy_punch()
		current_state = PlayerState.IDLE

func start_kick():
	print("Starting kick!")
	
	# Lock facing direction based on current movement or last facing
	if abs(velocity.x) > 10:
		facing_right = velocity.x > 0
	
	# Apply reversed flip for kick animation (sprites face left by default)
	player_sprite.flip_h = facing_right
	
	current_state = PlayerState.KICKING
	kick_timer = kick_duration
	kick_has_hit = false  # Reset hit flag for new kick
	
	# Position kick hitbox based on facing direction (EXACTLY like punch)
	var horizontal_offset := 45.0
	kick_area.position = Vector2(horizontal_offset if facing_right else -horizontal_offset, -20)
	
	# Hitbox starts disabled - will be enabled during animation window
	kick_area.visible = false
	kick_area.monitoring = false
	kick_area.monitorable = false

func stop_kick():
	# Disable kick hitbox when kick ends (same as punch logic)
	kick_area.visible = false
	kick_area.monitoring = false
	kick_area.monitorable = false
	
	# Restore correct flip state based on facing direction
	# (kick animation has reversed flip, so we need to restore normal flip logic)
	player_sprite.flip_h = not facing_right

func update_state():
	# Don't change state if punching, heavy punching, kicking, or dashing (they manage their own state)
	if current_state in [PlayerState.PUNCHING, PlayerState.HEAVY_PUNCHING, PlayerState.KICKING, PlayerState.DASHING]:
		# Update ONLY the sprite for these states, don't recalculate state
		update_sprite_for_committed_state()
		return
	
	if can_move_vertically:
		# In free movement area - determine state based on movement
		if abs(velocity.x) > 0 or abs(velocity.y) > 0:
			# Determine specific movement state
			if abs(velocity.y) > abs(velocity.x):
				if velocity.y < 0:
					current_state = PlayerState.WALK_UP
				else:
					current_state = PlayerState.WALK_DOWN
			else:
				current_state = PlayerState.WALKING
		else:
			current_state = PlayerState.IDLE
	else:
		# Outside free movement area - always idle (no movement allowed)
		current_state = PlayerState.IDLE
	
	# Update sprite direction and animation
	update_sprite_and_animation()

func update_sprite_and_animation():
	# Update facing direction for sprite ONLY when moving
	# Don't change facing during punch/dash to prevent flipping mid-action
	if abs(velocity.x) > 10:  # Small threshold to avoid jitter
		if velocity.x > 0:
			facing_right = true
			player_sprite.flip_h = false
		elif velocity.x < 0:
			facing_right = false
			player_sprite.flip_h = true
	
	# Play appropriate animation based on current state
	var animation_name = ""
	match current_state:
		PlayerState.IDLE:
			animation_name = "idle"
		PlayerState.WALKING:
			animation_name = "walking"
		PlayerState.WALK_UP:
			animation_name = "walk_up"
		PlayerState.WALK_DOWN:
			animation_name = "walk_down"
		PlayerState.PUNCHING:
			animation_name = "punching"
		PlayerState.HEAVY_PUNCHING:
			animation_name = "heavy_punch"
		PlayerState.KICKING:
			animation_name = "kicking"
		PlayerState.DASHING:
			animation_name = "dashing"
	
	# Only change animation if it's different from current
	if player_sprite.animation != animation_name and animation_name != "":
		player_sprite.play(animation_name)
		# Force sprite to stay centered when switching animations
		player_sprite.centered = true
		player_sprite.offset = Vector2.ZERO

func update_sprite_for_committed_state():
	# For punching, kicking, and dashing, just ensure the right animation is playing
	# Don't change facing direction or interrupt the animation
	var expected_animation = ""
	if current_state == PlayerState.PUNCHING:
		expected_animation = "punching"
	elif current_state == PlayerState.HEAVY_PUNCHING:
		expected_animation = "heavy_punch"
	elif current_state == PlayerState.KICKING:
		expected_animation = "kicking"
		# Don't update flip_h during kick - it was set in start_kick()
		if player_sprite.animation != expected_animation:
			player_sprite.play(expected_animation)
		return  # Early return to skip the normal flip logic
	elif current_state == PlayerState.DASHING:
		expected_animation = "dashing"
	
	# Only play if animation changed (prevents restarting)
	if player_sprite.animation != expected_animation:
		player_sprite.play(expected_animation)
		# Force sprite to stay centered when switching animations
		player_sprite.centered = true
		player_sprite.offset = Vector2.ZERO

func _on_punch_hit_box_area_entered(area):
	print("Punch detected area: ", area.name)
	# Enemy detection is handled by the enemy's HitBox area

func _on_heavy_punch_hit_box_area_entered(area):
	print("Heavy punch detected area: ", area.name)
	# Enemy detection is handled by the enemy's HitBox area
