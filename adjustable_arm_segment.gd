extends Node3D

@onready var arm_mesh = $ArmMeshPivot
@onready var arm_end = $ArmEnd

@export var arm_length = 1:
	get:
		return arm_length		
	set(value):
		value = clampf(value, 0.25, 2.5)
		arm_length = value
		update_arm_length(value)

@export var segment_child : Node3D

func update_arm_length(new_length):
	arm_mesh.scale.y = new_length
	arm_end.position.y = new_length
	
func _process(delta: float) -> void:
	if Input.is_action_pressed("Increase_Arm_Length"):
		arm_length += delta*1.5
	if Input.is_action_pressed("Decrease_Arm_length"):
		arm_length -= delta*1.5
		
	if segment_child:
		segment_child.global_position = arm_end.global_position
