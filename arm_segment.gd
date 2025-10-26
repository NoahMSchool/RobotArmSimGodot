@tool
extends Node3D

@export var arm_thickness : float = 0:
	set(value):
		arm_thickness = value
		if Engine.is_editor_hint():
			_rebuild()
@export var arm_length : float = 0.1: 
	set(value):
		arm_length = value
		if Engine.is_editor_hint():
			_rebuild()
@export var end_offset : float = 0.05:
	set(value):
		end_offset = value
		if Engine.is_editor_hint():
			_rebuild()
@export var extra_length : float = 0:
	set(value):
		extra_length = value
		if Engine.is_editor_hint():
			_rebuild()
	
@export var color : Color: 
	set(value):
		color = value
		if Engine.is_editor_hint():
			_rebuild()
@export var is_base : bool = false

@onready var arm_mesh: MeshInstance3D = $ArmMesh
@onready var segment_child : Node3D
@onready var tip : Node3D = $Tip

@export var servo_min = -90
@export var servo_max = 90
@export var servo_zero = 1

@onready var servo_min_rads = deg_to_rad(servo_min)
@onready var servo_max_rads = deg_to_rad(servo_max)
@onready var servo_zero_rads = deg_to_rad(servo_zero)


func set_seg_rotation(rotation_val : float):
	var clamped_rot = clampf(rotation_val, servo_min_rads, servo_max_rads)
	#print(servo_min_rads)
	#print(rotation_val)
	#print(servo_max_rads)
	if not is_base:
		rotation.x = clamped_rot
	else:
		rotation.y = clamped_rot

func get_seg_rotation():
	if not is_base:
		return rotation.x
	else:
		return rotation.y

func get_servo_rotation():
	return(get_seg_rotation()-servo_zero_rads)

func rot_in_range(rot)-> bool:
	return (rot < servo_max_rads and rot > servo_min_rads)
	
func rotate_seg(amount):
	set_seg_rotation(get_seg_rotation()+amount)

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	print("rebuilding")
	segment_child = get_child(get_child_count()-1)
	tip.position.y = arm_length
	tip.position.x = end_offset
	if segment_child:
		segment_child.position = tip.position
	arm_mesh.scale = Vector3(arm_thickness,arm_length+extra_length,arm_thickness)
	arm_mesh.position.y = arm_length/2
	
	var mat : StandardMaterial3D = arm_mesh.get_active_material(0)
	if not mat.resource_local_to_scene:
		mat = mat.duplicate()
		arm_mesh.set_surface_override_material(0, mat)
	mat.albedo_color = color



"""

"""
