extends "res://scripts/entities/boss_states/boss_state.gd"

class_name MissilePincerState

func enter(owner):
	owner.missile_pincer_timer = 0.0

func exit(owner):
	pass

func update(owner, delta):
	owner.handle_missile_pincer_state()
