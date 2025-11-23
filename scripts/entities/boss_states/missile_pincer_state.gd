extends "res://scripts/entities/boss_states/boss_state.gd"

class_name MissilePincerState

var missile_pincer_cooldown := 4.0
var missiles_per_side := 16
var missile_speed := 350.0
var missile_spawn_interval := 0.1
var missile_homing_strength := 3.0

func enter(owner):
	owner.missile_pincer_timer = 0.0

func exit(_owner):
	pass

func update(owner, delta):
	# Kiting logic (optional, or move to a shared state)
	if owner.player_ref:
		var distance_to_player = owner.global_position.distance_to(owner.player_ref.global_position)
		var direction_from_player = (owner.global_position - owner.player_ref.global_position).normalized()
		if distance_to_player < owner.kite_distance:
			owner.velocity = direction_from_player * owner.move_speed
		else:
			var perpendicular = Vector2(-direction_from_player.y, direction_from_player.x)
			owner.velocity = perpendicular * owner.move_speed * 0.7

	# Missile pincer attack logic
	owner.missile_pincer_timer += delta
	if owner.missile_pincer_timer >= missile_pincer_cooldown:
		_launch_missile_pincer(owner)
		owner.missile_pincer_timer = 0.0

func _launch_missile_pincer(owner):
	if not owner.player_ref:
		return
	print("Boss launching missile pincer attack!")
	for i in range(missiles_per_side):
		owner.get_tree().create_timer(i * missile_spawn_interval).timeout.connect(
			func(): _spawn_missile_from_side(owner, true, i)
		)
		owner.get_tree().create_timer(i * missile_spawn_interval).timeout.connect(
			func(): _spawn_missile_from_side(owner, false, i)
		)

func _spawn_missile_from_side(owner, from_left: bool, missile_index: int = 0):
	if not owner.player_ref:
		return
	print("Attempting to spawn missile from ", "left" if from_left else "right", " side")
	var direction_to_player = (owner.player_ref.global_position - owner.global_position).normalized()
	var perpendicular = Vector2()
	if from_left:
		perpendicular = Vector2(-direction_to_player.y, direction_to_player.x)
	else:
		perpendicular = Vector2(direction_to_player.y, -direction_to_player.x)
	var max_spread_angle = 25.0
	var progress = float(missile_index) / float(missiles_per_side - 1)
	var spread_factor = sin(progress * PI)
	var spread_angle = spread_factor * max_spread_angle
	var spread_radians = deg_to_rad(spread_angle)
	if not from_left:
		spread_radians = -spread_radians
	var spread_direction = perpendicular.rotated(spread_radians)
	var side_offset = perpendicular * 100.0
	var spawn_pos = owner.global_position + side_offset
	var initial_direction = spread_direction
	var missile = owner.enemy_tiny_scene.instantiate()
	missile.is_missile_mode = true
	missile.is_homing = true
	missile.homing_strength = missile_homing_strength
	owner.get_parent().add_child(missile)
	missile.global_position = spawn_pos
	missile.velocity = initial_direction * missile_speed
	if missile.has_method("set_missile_mode"):
		missile.set_missile_mode(true)
		print("Set missile mode enabled")
	else:
		print("WARNING: Missile doesn't have set_missile_mode method!")
	print("Spawned missile at position: ", spawn_pos, " with velocity: ", missile.velocity)
