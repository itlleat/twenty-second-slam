extends CharacterBody2D

signal enemy_died(enemy_position)

var health = 10
var flash_duration = 0.1
var shake_duration = 0.2
var shake_intensity = 6.0
var is_flashing = false
var is_shaking = false
var flash_timer = 0.0
var shake_timer = 0.0
var original_position = Vector2.ZERO
var original_sprite_position = Vector2.ZERO
@onready var enemy_body = $EnemyBody
@onready var enemy_sprite: AnimatedSprite2D
var flash_overlay: ColorRect

# Physics for flying when defeated
var is_flying = false
var flying_timer = 0.0
var flying_duration = 2.5
var gravity = 980.0
var bounce_damping = 0.8
var friction = 0.95
var original_collision_mask: int
var player_passthrough_enabled = true
var is_projectile_mode = false  # When true, skip normal enemy behavior
var is_ring_mode = false  # When true, position controlled by boss (no physics)

func _ready():
	enemy_body = $EnemyBody
	if has_node("EnemySprite"):
		enemy_sprite = $EnemySprite
	elif has_node("AnimatedSprite2D"):
		enemy_sprite = $AnimatedSprite2D
	flash_overlay = $FlashOverlay if has_node("FlashOverlay") else null
	original_position = enemy_body.position
	if enemy_sprite:
		original_sprite_position = enemy_sprite.position
	
	# Ensure flash overlay starts invisible
	if flash_overlay:
		flash_overlay.visible = false
	
	# Store original collision mask for later use
	original_collision_mask = collision_mask
	
	# Only do normal enemy setup if not in projectile mode
	if not is_projectile_mode:
		# Add collision exceptions for player and larger enemies so they can pass through
		var player = get_node_or_null("../Player")
		if not player:
			player = get_node_or_null("../PlayerNew")
		if player:
			add_collision_exception_with(player)
			print("Added collision exception with player for desk_lamp")
		
		# Find and add exceptions for all larger enemies in the scene
		var parent = get_parent()
		if parent:
			for child in parent.get_children():
				if child != self and child.has_method("take_hit") and child.name.begins_with("Enemy"):
					add_collision_exception_with(child)
					print("Added collision exception with larger enemy: ", child.name)
		
		# Connect the hit detection signal
		if has_node("HitBox"):
			$HitBox.area_entered.connect(_on_desk_lamp_hit_box_area_entered)
		else:
			print("Warning: HitBox node not found for desk_lamp")

func set_projectile_mode(enabled: bool):
	is_projectile_mode = enabled
	if enabled:
		# Immediately start flying behavior
		is_flying = true
		flying_timer = flying_duration
		
		# Add collision exception with boss and other enemies
		var parent = get_parent()
		if parent:
			for child in parent.get_children():
				if (child.name == "Enemy" or 
					child.name.begins_with("Enemy") or
					child.name.begins_with("Chair") or
					child.name.begins_with("DeskLamp") or
					child.is_in_group("enemies")) and child != self:
					add_collision_exception_with(child)
					print("Desk_lamp added collision exception with: ", child.name)
			
			# Add collision exception with player
			var player = get_node_or_null("../Player")
			if not player:
				player = get_node_or_null("../PlayerNew")
			if player:
				add_collision_exception_with(player)
				print("Desk_lamp added collision exception with player")
		
		print("Desk_lamp set to projectile mode with velocity: ", velocity)

func _process(delta):
	if is_flying:
		flying_timer -= delta
		if flying_timer <= 0:
			# Stop flying and despawn
			is_flying = false
			velocity = Vector2.ZERO
			print("Desk_lamp came to rest and despawning")
			queue_free()  # Despawn the desk_lamp
	else:
		# Normal behavior when not flying
		if is_flashing:
			flash_timer -= delta
			if flash_timer <= 0:
				is_flashing = false
				if enemy_sprite:
					enemy_sprite.modulate = Color(1, 1, 1, 1)  # Reset to normal

		if is_shaking:
			shake_timer -= delta
			if shake_timer <= 0:
				is_shaking = false
				if enemy_sprite:
					enemy_sprite.position = original_sprite_position
			else:
				# Random shake offset
				var offset = Vector2(
					randf_range(-1, 1) * shake_intensity,
					randf_range(-1, 1) * shake_intensity
				)
				if enemy_sprite:
					enemy_sprite.position = original_sprite_position + offset

func take_hit(damage: int = 1):
	health -= damage
	print("Desk_lamp took hit! Health now: ", health)

	# Start flash effect
	is_flashing = true
	flash_timer = flash_duration
	if enemy_sprite:
		enemy_sprite.modulate = Color(10, 10, 10, 1)  # Bright white flash

	# Start shake effect
	is_shaking = true
	shake_timer = shake_duration
	if enemy_sprite:
		original_sprite_position = enemy_sprite.position  # Store current sprite position for shake

	if health <= 0:
		print("Desk_lamp defeated at position: ", global_position)
		start_flying()  # Start flying instead of dying

func _physics_process(delta):
	# Skip all physics if in ring mode (position controlled by boss)
	if is_ring_mode:
		return
	
	# Only apply gravity when flying (after HP is depleted)
	# BUT: Don't apply gravity if in projectile mode (constant velocity)
	if is_flying and not is_projectile_mode:
		velocity.y += gravity * delta
	
	if is_flying and not is_projectile_mode:
		# Apply friction to horizontal movement when flying
		# (Skip for projectiles - they maintain constant velocity)
		velocity.x *= friction
		
		# Handle bouncing off any solid surface
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collision_normal = collision.get_normal()
			var collider = collision.get_collider()
			
			# Skip bouncing off the player and larger enemies
			if collider and (collider.name == "Player" or collider.name == "PlayerNew" or collider.name.begins_with("Enemy")):
				continue
				
			# Calculate bounce based on collision normal
			var velocity_dot_normal = velocity.dot(collision_normal)
			if velocity_dot_normal < 0:  # Moving into the surface
				# Reflect velocity off the surface with damping
				velocity = velocity - 2 * velocity_dot_normal * collision_normal
				velocity *= bounce_damping
	
	# Only use physics movement when flying
	if is_flying:
		move_and_slide()
	else:
		# When not flying, stay completely stationary
		velocity = Vector2.ZERO

func start_flying():
	is_flying = true
	flying_timer = flying_duration
	
	# Get player's facing direction
	var player = get_node_or_null("../Player")
	if not player:
		player = get_node_or_null("../PlayerNew")
	var player_facing_right = true  # Default fallback
	
	if player and player.has_method("get") and "facing_right" in player:
		player_facing_right = player.facing_right
	elif player and "facing_right" in player:
		player_facing_right = player.facing_right
	
	# Apply flying force in player's facing direction
	var force_magnitude = randf_range(1800, 2200)  # Very powerful knockback
	var force_x = force_magnitude if player_facing_right else -force_magnitude
	var force_y = randf_range(-600, -300)  # Upward force
	velocity = Vector2(force_x, force_y)
	
	# Disable hit detection while flying (deferred to avoid collision system conflicts)
	if has_node("HitBox"):
		$HitBox.set_deferred("monitoring", false)
		$HitBox.set_deferred("monitorable", false)

func _on_desk_lamp_hit_box_area_entered(area):
	# Skip hit detection if in projectile mode
	if is_projectile_mode:
		return
		
	if area.name == "PunchHitBox" and not is_flying:
		print("Desk_lamp hit by punch!")
		take_hit()
