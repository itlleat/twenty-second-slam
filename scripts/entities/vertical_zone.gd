extends Area2D

func _ready():
	# Enable free movement immediately
	call_deferred("setup_free_movement_area")

func setup_free_movement_area():
	# Find the player and enable free movement
	var player = get_node("../Player")
	if player:
		player.can_move_vertically = true
		print("Player can now move freely in all directions!")
