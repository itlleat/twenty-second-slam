extends CharacterBody2D

signal enemy_died(enemy_position)

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

func _ready():
	enemy_body = $EnemyBody
	flash_overlay = $FlashOverlay
	original_position = enemy_body.position
	
	# Ensure flash overlay starts invisible
	flash_overlay.visible = false
	
	# Connect the hit detection signal
	$HitBox.area_entered.connect(_on_hit_box_area_entered)

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
