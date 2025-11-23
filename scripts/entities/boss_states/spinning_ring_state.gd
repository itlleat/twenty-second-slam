extends "res://scripts/entities/boss_states/boss_state.gd"

class_name SpinningRingState

var spinning_ring_cooldown := 3.0
var spinning_ring_duration := 2.5
var spinning_ring_projectile_count := 12
var spinning_ring_projectile_speed := 250.0
var spinning_ring_radius := 220.0

func enter(owner):
	owner.spinning_ring_timer = 0.0
	owner.spinning_ring_active = false

func exit(owner):
	owner.spinning_ring_active = false

func update(owner, delta):
	owner.spinning_ring_timer += delta
	if not owner.spinning_ring_active and owner.spinning_ring_timer >= spinning_ring_cooldown:
		owner.spinning_ring_active = true
		owner.spinning_ring_timer = 0.0
		_launch_spinning_ring(owner)
	elif owner.spinning_ring_active and owner.spinning_ring_timer >= spinning_ring_duration:
		owner.spinning_ring_active = false
		owner.spinning_ring_timer = 0.0

func _launch_spinning_ring(owner):
	print("Boss launching spinning ring attack!")
	var angle_step = TAU / spinning_ring_projectile_count
	for i in range(spinning_ring_projectile_count):
		var angle = i * angle_step
		var direction = Vector2(cos(angle), sin(angle))
		var spawn_pos = owner.global_position + direction * spinning_ring_radius
		var projectile = owner.enemy_small_scene.instantiate()
		projectile.global_position = spawn_pos
		projectile.velocity = direction * spinning_ring_projectile_speed
		owner.get_parent().add_child(projectile)
		if projectile.has_method("set_spinning_mode"):
			projectile.set_spinning_mode(true)
		print("Spawned spinning ring projectile at position: ", spawn_pos, " with velocity: ", projectile.velocity)
