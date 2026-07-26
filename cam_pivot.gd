extends  Node3D

var cam_sens = 0.001
var clicking := false

func _unhandled_input(event: InputEvent) -> void:

	if event is InputEventMouseMotion and Input.get_action_strength("click")>0:
		rotation.y -= event.relative.x*cam_sens
		rotation.x -= event.relative.y*cam_sens
		rotation.x = clamp(rotation.x, -PI/8, PI/8)
