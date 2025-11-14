extends Area2D

func _ready():
	# Enable free movement immediately and create walls
	call_deferred("setup_free_movement_area")

func setup_free_movement_area():
	# Find the player and enable free movement
	var player = get_node("../Player")
	if player:
		player.can_move_vertically = true
		print("Player can now move freely in all directions!")
	
	# Create the boundary walls
	create_invisible_walls()

func create_invisible_walls():
	# Get the collision shape to create walls around it
	var collision_shape = $CollisionShape2D
	if not collision_shape or not collision_shape.shape:
		return
		
	var shape = collision_shape.shape
	if not shape is RectangleShape2D:
		return
		
	var rect_shape = shape as RectangleShape2D
	var area_pos = global_position + collision_shape.position
	var half_size = rect_shape.size / 2
	var wall_thickness = 50.0
	
	# Create 4 walls around the movement area
	create_wall(Vector2(area_pos.x, area_pos.y - half_size.y - wall_thickness/2), Vector2(rect_shape.size.x + wall_thickness*2, wall_thickness)) # Top
	create_wall(Vector2(area_pos.x, area_pos.y + half_size.y + wall_thickness/2), Vector2(rect_shape.size.x + wall_thickness*2, wall_thickness)) # Bottom  
	create_wall(Vector2(area_pos.x - half_size.x - wall_thickness/2, area_pos.y), Vector2(wall_thickness, rect_shape.size.y)) # Left
	create_wall(Vector2(area_pos.x + half_size.x + wall_thickness/2, area_pos.y), Vector2(wall_thickness, rect_shape.size.y)) # Right

func create_wall(pos: Vector2, size: Vector2):
	var wall = StaticBody2D.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	shape.size = size
	collision.shape = shape
	wall.add_child(collision)
	wall.global_position = pos
	
	# Add to parent scene, not to this Area2D
	get_parent().add_child(wall)
	print("Created invisible wall at: ", pos, " size: ", size)

# Removed enter/exit logic - player is always in free movement area
