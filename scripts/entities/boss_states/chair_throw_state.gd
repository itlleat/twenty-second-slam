extends "res://scripts/entities/boss_states/boss_state.gd"

class_name ChairThrowState


# State-local variables
var chair_throw_cooldown := 2.5
var chair_speed := 400.0
var use_chair_2 := false

func enter(owner):
	owner.chair_throw_timer = 0.0

func exit(owner):
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

	# Chair throw attack logic
	owner.chair_throw_timer += delta
	if owner.chair_throw_timer >= chair_throw_cooldown:
		_throw_chair_at_player(owner)
		owner.chair_throw_timer = 0.0

func _throw_chair_at_player(owner):
	if not owner.player_ref:
		return
	print("Boss throwing chair at player!")
	var direction_to_player = (owner.player_ref.global_position - owner.global_position).normalized()
	var chair_scene = owner.chair_2_scene if use_chair_2 else owner.chair_1_scene
	use_chair_2 = not use_chair_2
	var chair = chair_scene.instantiate()
	chair.is_projectile_mode = true
	chair.is_homing = true
	chair.homing_strength = 2.0
	owner.get_parent().add_child(chair)
	chair.global_position = owner.global_position
	chair.velocity = direction_to_player * chair_speed
	if chair.has_method("set_projectile_mode"):
		chair.set_projectile_mode(true)
