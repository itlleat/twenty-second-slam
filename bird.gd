extends Node2D



# Bird movement parameters
var velocity: Vector2 = Vector2(120, 0)
var wobble_speed: float = 1.5
var wobble_amount: float = 20.0
var wobble_offset: float = randf() * TAU

func set_wobble(speed: float, amount: float) -> void:
	wobble_speed = speed
	wobble_amount = amount

func _ready() -> void:
	# Optionally randomize wobble offset for each bird
	wobble_offset = randf() * TAU
	var sprite = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
	if sprite:
		sprite.play()



func _process(delta: float) -> void:
	# Add vertical sine wobble for realism
	velocity.y = sin((Time.get_ticks_msec() / 1000.0) * wobble_speed + wobble_offset) * wobble_amount
	position += velocity * delta
