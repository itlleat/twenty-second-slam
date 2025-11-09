extends CharacterBody2D

enum PlayerState {
	IDLE,
	WALKING,
	JUMPING,
	PUNCHING
}

var current_state = PlayerState.IDLE
var move_speed = 600.0
var jump_force = -475.0
var gravity = 980.0
var can_punch = true
var punch_cooldown = 0.06
var punch_timer = 0.0
var facing_right = true

var punch_area: Area2D
var punch_rect: ColorRect
var player_body: ColorRect

func _ready():

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
	match current_state:
		PlayerState.IDLE:
			handle_idle_state(delta)
		PlayerState.WALKING:
			handle_walking_state(delta)
		PlayerState.JUMPING:
			handle_jumping_state(delta)
		PlayerState.PUNCHING:
			handle_punching_state(delta)
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	move_and_slide()
	update_state()

func handle_idle_state(_delta):
	if not is_on_floor():
		current_state = PlayerState.JUMPING
		return
	
	velocity.x = 0
	handle_movement_input()

func handle_walking_state(_delta):
	if not is_on_floor():
		current_state = PlayerState.JUMPING
		return
	
	handle_movement_input()

func handle_jumping_state(_delta):
	handle_movement_input()
	
	if is_on_floor():
		if abs(velocity.x) > 0:
			current_state = PlayerState.WALKING
		else:
			current_state = PlayerState.IDLE

func handle_punching_state(delta):
	velocity.x = 0
	punch_timer -= delta
	if punch_timer <= 0:
		current_state = PlayerState.IDLE
		can_punch = true
		punch_area.visible = false
		# Disable collision when not punching
		punch_area.monitoring = false
		punch_area.monitorable = false

func handle_movement_input():
	var input_dir = Input.get_axis("move_left", "move_right")
	velocity.x = input_dir * move_speed
	
	# Update facing direction
	if input_dir > 0:
		facing_right = true
	elif input_dir < 0:
		facing_right = false
	
	# Update punch hitbox position based on facing direction
	punch_area.position = Vector2(30 if facing_right else -70, -10)
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
		current_state = PlayerState.JUMPING
	
	if Input.is_action_just_pressed("punch") and can_punch:
		start_punch()

func start_punch():
	current_state = PlayerState.PUNCHING
	can_punch = false
	punch_timer = punch_cooldown
	punch_area.visible = true  # Show the punch hitbox
	# Enable collision only while punching
	punch_area.monitoring = true
	punch_area.monitorable = true

func update_state():
	if current_state != PlayerState.PUNCHING:
		if is_on_floor():
			if abs(velocity.x) > 0:
				current_state = PlayerState.WALKING
			else:
				current_state = PlayerState.IDLE
