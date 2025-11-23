extends "res://scripts/entities/boss_states/boss_state.gd"

class_name SpinningRingState

func enter(owner):
	# Setup for spinning ring attack
	owner.spinning_ring_angle = 0.0
	owner.inner_ring_angle = 0.0
	owner.start_spinning_ring()

func exit(owner):
	# Cleanup if needed
	pass

func update(owner, delta):
	owner.handle_spinning_ring_state()
