extends CharacterBody2D
class_name BaseEnemy

# Base Enemy State Machine
# All enemies inherit from this class for consistent behavior patterns

signal enemy_died(enemy_position)
signal state_changed(old_state, new_state)

enum EnemyState {
	SPAWNING,
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	HIT_STUNNED,
	FLYING,
	DEAD
}

# Core state machine variables
var current_state: EnemyState = EnemyState.SPAWNING
var previous_state: EnemyState

# Base enemy stats - override in child classes
@export var max_health: int = 10
@export var move_speed: float = 100.0
@export var detection_range: float = 200.0
@export var attack_range: float = 50.0
@export var attack_damage: int = 1

# Current stats
var health: int
var player_ref: CharacterBody2D

# Visual feedback
@export var flash_duration: float = 0.1
@export var shake_duration: float = 0.2
@export var shake_intensity: float = 6.0
var is_flashing: bool = false
var is_shaking: bool = false
var flash_timer: float = 0.0
var shake_timer: float = 0.0
var original_position: Vector2

# Node references - setup in child classes
@onready var enemy_body: Node2D
@onready var flash_overlay: ColorRect
@onready var hit_box: Area2D

# State timers and data
var state_timer: float = 0.0
var state_data: Dictionary = {}

func _ready():
	health = max_health
	find_player()
	setup_nodes()
	connect_signals()
	initialize_enemy()
	change_state(EnemyState.IDLE)

func _physics_process(delta):
	state_timer += delta
	update_visual_effects(delta)
	
	# State machine core
	match current_state:
		EnemyState.SPAWNING:
			handle_spawning_state(delta)
		EnemyState.IDLE:
			handle_idle_state(delta)
		EnemyState.PATROL:
			handle_patrol_state(delta)
		EnemyState.CHASE:
			handle_chase_state(delta)
		EnemyState.ATTACK:
			handle_attack_state(delta)
		EnemyState.HIT_STUNNED:
			handle_hit_stunned_state(delta)
		EnemyState.FLYING:
			handle_flying_state(delta)
		EnemyState.DEAD:
			handle_dead_state(delta)
	
	# Apply movement if not in static states
	if current_state not in [EnemyState.DEAD, EnemyState.HIT_STUNNED]:
		move_and_slide()

# Virtual functions - override in child classes for custom behavior
func initialize_enemy():
	# Override this in child classes for setup
	pass

func setup_nodes():
	# Override this to setup node references
	# Example:
	# enemy_body = $EnemyBody
	# flash_overlay = $FlashOverlay  
	# hit_box = $HitBox
	pass

func connect_signals():
	# Override this to connect custom signals
	if hit_box:
		hit_box.area_entered.connect(_on_hit_box_area_entered)

# State handling functions - override for custom behavior
func handle_spawning_state(_delta):
	# Default: immediately go to idle
	change_state(EnemyState.IDLE)

func handle_idle_state(_delta):
	# Default idle behavior - look for player
	velocity = Vector2.ZERO
	if can_see_player():
		change_state(EnemyState.CHASE)

func handle_patrol_state(_delta):
	# Default patrol - override in child classes
	velocity = Vector2.ZERO

func handle_chase_state(_delta):
	# Default chase behavior
	if not player_ref:
		change_state(EnemyState.IDLE)
		return
	
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	
	if distance_to_player <= attack_range:
		change_state(EnemyState.ATTACK)
	elif distance_to_player > detection_range:
		change_state(EnemyState.IDLE)
	else:
		# Move towards player
		var direction = (player_ref.global_position - global_position).normalized()
		velocity = direction * move_speed

func handle_attack_state(_delta):
	# Default attack - override in child classes
	velocity = Vector2.ZERO
	if state_timer > 1.0:  # Attack duration
		change_state(EnemyState.IDLE)

func handle_hit_stunned_state(_delta):
	# Default hit stun
	velocity = Vector2.ZERO
	if state_timer > 0.3:  # Stun duration
		if health <= 0:
			change_state(EnemyState.FLYING)
		else:
			change_state(EnemyState.IDLE)

func handle_flying_state(_delta):
	# Default flying behavior - similar to your enemy_small
	velocity.y += 980.0 * _delta  # Gravity
	velocity.x *= 0.95  # Friction
	
	if state_timer > 2.5:  # Flying duration
		change_state(EnemyState.DEAD)

func handle_dead_state(_delta):
	# Default death - cleanup
	if state_timer > 0.1:  # Brief delay
		emit_signal("enemy_died", global_position)
		queue_free()

# State management
func change_state(new_state: EnemyState):
	if new_state == current_state:
		return
	
	var old_state = current_state
	exit_state(current_state)
	
	previous_state = current_state
	current_state = new_state
	state_timer = 0.0
	state_data.clear()
	
	enter_state(new_state)
	emit_signal("state_changed", old_state, new_state)
	
	print(name, " changed state: ", EnemyState.keys()[old_state], " -> ", EnemyState.keys()[new_state])

func enter_state(state: EnemyState):
	# Override in child classes for state entry logic
	match state:
		EnemyState.HIT_STUNNED:
			start_visual_feedback()

func exit_state(_state: EnemyState):
	# Override in child classes for state exit logic
	pass

# Utility functions
func find_player():
	# Simplified player finding to avoid loading issues
	player_ref = get_node_or_null("../Player")
	if not player_ref:
		# Use call_deferred to find player after scene is fully loaded
		call_deferred("_find_player_deferred")

func _find_player_deferred():
	if not player_ref and get_tree() and get_tree().current_scene:
		var scene_root = get_tree().current_scene
		for child in scene_root.get_children():
			if child.name == "Player":
				player_ref = child
				break

func can_see_player() -> bool:
	if not player_ref:
		return false
	
	var distance = global_position.distance_to(player_ref.global_position)
	return distance <= detection_range

func get_distance_to_player() -> float:
	if not player_ref:
		return INF
	return global_position.distance_to(player_ref.global_position)

func get_direction_to_player() -> Vector2:
	if not player_ref:
		return Vector2.ZERO
	return (player_ref.global_position - global_position).normalized()

# Combat system
func take_hit(damage: int = 1):
	health -= damage
	print(name, " took hit! Health now: ", health, "/", max_health)
	
	if current_state != EnemyState.FLYING and current_state != EnemyState.DEAD:
		change_state(EnemyState.HIT_STUNNED)

func start_visual_feedback():
	is_flashing = true
	flash_timer = flash_duration
	if flash_overlay:
		flash_overlay.visible = true
	
	is_shaking = true
	shake_timer = shake_duration
	if enemy_body:
		original_position = enemy_body.position

func update_visual_effects(delta):
	# Handle flashing
	if is_flashing:
		flash_timer -= delta
		if flash_timer <= 0:
			is_flashing = false
			if flash_overlay:
				flash_overlay.visible = false
	
	# Handle shaking
	if is_shaking:
		shake_timer -= delta
		if shake_timer <= 0:
			is_shaking = false
			if enemy_body:
				enemy_body.position = original_position
				if flash_overlay:
					flash_overlay.position = enemy_body.position
		else:
			if enemy_body:
				var offset = Vector2(
					randf_range(-1, 1) * shake_intensity,
					randf_range(-1, 1) * shake_intensity
				)
				enemy_body.position = original_position + offset
				if flash_overlay:
					flash_overlay.position = enemy_body.position

# Signal handlers
func _on_hit_box_area_entered(area):
	if area.name == "PunchHitBox" and current_state not in [EnemyState.FLYING, EnemyState.DEAD]:
		print(name, " hit by punch!")
		take_hit()