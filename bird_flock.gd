extends Node2D



# Spawns a flock of birds that fly to the right with natural spread
var BirdScene := preload("res://bird.tscn")
var flock_size := 8

func _ready() -> void:
	for i in range(flock_size):
		var bird = BirdScene.instantiate()
		# Spread birds horizontally and vertically for a natural look
		bird.position = Vector2(randf_range(0, 100), randf_range(0, 200))
		# Adjust velocity so birds fly up and to the right
		var base_speed_x = 120 + randf_range(-30, 30)
		var base_speed_y = -60 + randf_range(-20, 20) # Negative y is up in Godot
		bird.velocity = Vector2(base_speed_x, base_speed_y)
		# Optionally randomize wobble parameters if exposed
		if bird.has_method("set_wobble"):
			bird.set_wobble(randf_range(1.0, 2.0), randf_range(10, 30))
		add_child(bird)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
