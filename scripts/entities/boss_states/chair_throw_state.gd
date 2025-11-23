extends "res://scripts/entities/boss_states/boss_state.gd"

class_name ChairThrowState

func enter(owner):
	owner.chair_throw_timer = 0.0

func exit(owner):
	pass

func update(owner, delta):
	owner.handle_chair_throw_state()
