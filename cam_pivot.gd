extends Node3D

var rotate_time = 3
var rotate_speed = 2*PI

func _process(delta: float) -> void:
	return
	var rotation_dir = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	rotate_y(rotation_dir*delta*PI/3)
