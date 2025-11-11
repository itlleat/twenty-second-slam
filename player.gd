extends CharacterBody2D

enum PlayerState {
	IDLE,
	WALKING,
	WALK_UP,
	WALK_DOWN,
	DASHING
}

var current_state = PlayerState.IDLE
var move_speed = 600.0
var dash_force = 1800.0
var dash_duration = 0.19
var gravity = 980.0
var punch_flash_rate = 10.0  # Flashes per second
var punch_flash_timer = 0.0
var is_punching = false
var dash_timer = 0.0
var is_dashing = false
var facing_right = true

var punch_area: Area2D
var punch_rect: ColorRect
var player_body: ColorRect
var can_move_vertically = false

func _ready():
	# Create and add camera
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

	punch_area = $PunchHitBox
	punch_rect = $PunchHitBox/PunchRect
	
	# Start with punch hitbox disabled
	punch_area.visible = false
	punch_area.monitoring = false
	punch_area.monitorable = false
	
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
	# Handle punch input - completely asynchronous, works anywhere
	if Input.is_action_pressed("punch"):
		if not is_punching:
			start_punch()
		handle_punch_flash(delta)
	else:
		if is_punching:
			stop_punch()
	
	# Handle dash input - only works in movement areas
	if Input.is_action_just_pressed("jump") and can_move_vertically:
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

func handle_dashing_state(delta):
	dash_timer -= delta
	if dash_timer <= 0:
		# End dash
		current_state = PlayerState.IDLE
		is_dashing = false
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
	is_dashing = true
	dash_timer = dash_duration
	
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
	else:
		# No input - dash in facing direction
		dash_direction = Vector2(1 if facing_right else -1, 0)
	
	velocity = dash_direction * dash_force
	print("Dashing in direction: ", dash_direction)



func start_punch():
	is_punching = true
	punch_flash_timer = 0.0
	
	# Position punch hitbox based on facing direction
	var horizontal_offset := 40.0
	punch_area.position = Vector2(horizontal_offset if facing_right else -horizontal_offset, -40)
	
	# Enable collision while punching
	punch_area.monitoring = true
	punch_area.monitorable = true

func stop_punch():
	is_punching = false
	punch_area.visible = false
	punch_area.monitoring = false
	punch_area.monitorable = false
	# Don't change state here - let update_state handle it

func handle_punch_flash(delta):
	punch_flash_timer += delta
	var flash_period = 1.0 / punch_flash_rate
	
	# Update punch position based on current facing direction
	var horizontal_offset := 40.0
	punch_area.position = Vector2(horizontal_offset if facing_right else -horizontal_offset, -40)
	
	# Toggle both visibility AND collision detection with each flash
	var should_be_active = fmod(punch_flash_timer, flash_period) < (flash_period * 0.5)
	punch_area.visible = should_be_active
	punch_area.monitoring = should_be_active
	punch_area.monitorable = should_be_active

func update_state():
	# Dashing takes priority for movement state
	if is_dashing:
		current_state = PlayerState.DASHING
		return
	
	# Handle movement states based on actual movement, not punch state
	if can_move_vertically:
		# In free movement area - use any movement for walking state
		if abs(velocity.x) > 0 or abs(velocity.y) > 0:
			current_state = PlayerState.WALKING
		else:
			current_state = PlayerState.IDLE
	else:
		# Outside free movement area - always idle (no movement allowed)
		current_state = PlayerState.IDLE
