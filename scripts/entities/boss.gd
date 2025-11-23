extends CharacterBody2D


var current_state = null
var current_state_name = ""
var attack_states = [
	preload("res://scripts/entities/boss_states/missile_pincer_state.gd").new(),
	preload("res://scripts/entities/boss_states/chair_throw_state.gd").new()
]


# boss properties
var health = 100
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
var enemy_small_scene = preload("res://scenes/enemies/enemy_small.tscn")
var enemy_tiny_scene = preload("res://scenes/enemies/enemy_tiny.tscn")

# Chair throw attack dependencies
var chair_1_scene = preload("res://scenes/enemies/chair_1.tscn")
var chair_2_scene = preload("res://scenes/enemies/chair_2.tscn")
var chair_throw_timer = 0.0

# kite 
var player_ref: CharacterBody2D
var kite_distance = 250.0 # Distance to maintain from player
var move_speed = 150.0 # Boss movement speed
var attack_windup_distance = 150.0

# Missile pincer attack
var missile_pincer_timer: float = 0.0


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
	# No need to start random attack loop

func _find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
	else:
		# Fallback: search by name
		player_ref = get_node_or_null("../Player")


func _physics_process(_delta):
	if player_ref:
		# Update all attack states in parallel
		for state in attack_states:
			state.update(self, get_physics_process_delta_time())
		move_and_slide()

func handle_kiting_state():
	kite_from_player()

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

