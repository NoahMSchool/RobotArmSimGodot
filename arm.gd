extends Node3D

var requests_off = false

@onready var reachable_mat = preload("res://blueglow.tres")
@onready var unreachable_mat = preload("res://redglow.tres")

@onready var base_cube = $Base_Cube
@onready var base_seg = $Base_Cube/Base_Seg
@onready var middle_seg = $Base_Cube/Base_Seg/Middle_Seg
@onready var end_seg = $Base_Cube/Base_Seg/Middle_Seg/Effector_Seg

var base_angle_range : Array[float]
var middle_angle_range : Array[float]
var end_angle_range : Array[float]

var base_cube_height : float
var base_length : float
var middle_length : float
var end_length : float
var magnet_height : float = 0.025


@onready var target_node = $Target
@onready var target_mesh = $Target/MeshInstance3D
#@onready var target_radius = 0.007

@export var target_pos : Vector3 = Vector3(0,0.15,-0.075):
	set(value):
		target_node.position = value
		target_pos = value
@onready var http_node : HTTPRequest = $HTTP
var api_base_url = "http://raspberrypi.local:8080"

@export var arm_speed_degrees = 30
@onready var arm_speed = deg_to_rad(arm_speed_degrees)

var save_1 : Vector3 = target_pos
var save_2 : Vector3 = target_pos

var moved = false

#Work Envelope
@onready var max_envelope_mesh : MeshInstance3D = $MaxEnvelopeMesh

var min_distance : float
var max_distance : float

func magnet(state : bool):
	var state_string = "on" if state else "off"
	print("mag")
	http_node.request(api_base_url+"/magnet?status="+state_string)

func servo_request():
	if not moved or requests_off:
		return
	var turntable_angle = rad_to_deg(base_seg.get_servo_rotation())
	#middleangle is clockwise on api so inconsistent
	var middle_angle = -rad_to_deg(middle_seg.get_servo_rotation())
	var end_angle = rad_to_deg(end_seg.get_servo_rotation())
	
	#print(end_angle)
	var fields = { "turntable": turntable_angle, "seg_1": middle_angle, "seg_2" : end_angle}
	var query_string : String = HTTPClient.new().query_string_from_dict(fields)

	var url = api_base_url+"/servos?"+query_string
	#print(url)
	http_node.request(url)
	moved = false
	
func _ready() -> void:

	max_distance = end_seg.arm_length + middle_seg.arm_length
	min_distance = abs(end_seg.arm_length - middle_seg.arm_length)
	#print(max_distance,  " : ", min_distance)
	"""
	max_envelope_mesh.position = Vector3(0,0,base_seg.arm_length+base_cube.arm_length)
	max_envelope_mesh.scale *= max_distance
	max_envelope_mesh.visible = true
	
	target_mesh.transform.origin.y = -target_radius
	target_mesh.scale = 2*target_radius*Vector3.ONE
	"""
	
	base_angle_range = [base_seg.servo_min_rads, base_seg.servo_max_rads]
	middle_angle_range = [middle_seg.servo_min_rads, middle_seg.servo_max_rads]
	end_angle_range = [end_seg.servo_min_rads, end_seg.servo_max_rads]
	
	base_cube_height = base_cube.arm_length
	base_length = base_seg.arm_length
	middle_length = middle_seg.arm_length
	end_length = end_seg.arm_length


	
func _process(delta: float) -> void:
	#if Input.is_action_pressed("w"):
		#end_seg.rotate_seg(delta*arm_speed)
		#moved = true
	#if Input.is_action_pressed("a"):
		#end_seg.rotate_seg(-delta*arm_speed)
		#moved = true
	#if Input.is_action_pressed("e"):
		#middle_seg.rotate_seg(-delta*arm_speed)
		#moved = true
	#if Input.is_action_pressed("s"):
		#middle_seg.rotate_seg(delta*arm_speed)
		#moved = true
	#
	#if Input.is_action_pressed("r"):
		#base_seg.rotate_seg(delta*arm_speed)
		#moved = true
	#if Input.is_action_pressed("d"):
		#base_seg.rotate_seg(-delta*arm_speed)
		#moved = true
		
		
	if Input.is_action_just_pressed("MagOn"):
		magnet(true)
	if Input.is_action_just_pressed("MagOff"):
		magnet(false)
	
	var target_dir = Vector3(
		Input.get_action_strength("right")-Input.get_action_strength("left"),
		Input.get_action_strength("space")-Input.get_action_strength("shift"),
		Input.get_action_strength("down")-Input.get_action_strength("up")
	)
	var new_target_pos = target_pos + target_dir.normalized()*delta*0.2
	if new_target_pos.y-magnet_height>0 and absf(new_target_pos.x)<0.5:
		target_pos = new_target_pos
	
	if target_dir.length()>0:
		moved = true
	"""
	var length_to_target = (target_pos-Vector3(0,base_cube_height+magnet_height + base_length, 0)).length()
	if length_to_target < min_distance or length_to_target > max_distance:
		target_mesh.material_override = unreachable_mat
	"""
	if Input.is_action_just_pressed("r") or true:
		var ik_angles = calculate_ik_angles()
		if ik_angles:
			#print(ik_angles)
			target_mesh.material_override = reachable_mat
			base_seg.set_seg_rotation(ik_angles[0])
			middle_seg.set_seg_rotation(ik_angles[1])
			end_seg.set_seg_rotation(ik_angles[2])
		
		else:
			target_mesh.material_override = unreachable_mat
			#print("no_solutions to ik")
	

	if Input.is_action_just_pressed("ctl1"):
		save_1 = target_pos
		print("saving to 1")
	elif Input.is_action_just_pressed("1key"):
		target_pos = save_1
		moved = true		
		print("moving to 1")

	if Input.is_action_just_pressed("ctl2"):
		save_2 = target_pos
		print("saving to 2")
	elif Input.is_action_just_pressed("2key"):
		target_pos = save_2
		moved = true
		print("moving to 2")

	
func _on_request_timer_timeout() -> void:
	#print(rad_to_deg(seg_1.get_servo_rotation()))
	servo_request()

func calculate_ik_angles():
	var solvable = true
	var turn_angle = 0
	var base_angle = 0
	var end_angle = 0
	
	var origin = Vector3(0,base_cube_height + base_length, 0)
	var to_target = target_pos-origin+Vector3(0,magnet_height,0)
	var length_to_target = to_target.length()
	turn_angle = atan2(-to_target.x, -to_target.z)
	if not(turn_angle > base_angle_range[0] and turn_angle < base_angle_range[1]):
		return null
	
	if length_to_target < min_distance or length_to_target > max_distance:
		return null
		
	var center = acos((middle_length**2+end_length**2-length_to_target**2)/(2*end_length*middle_length))
	if center<0 or center>PI:
		return null
	
	var angle_1 = PI-atan2(sqrt(to_target.x**2+to_target.z**2),-to_target.y)-asin((end_length*sin(center))/length_to_target)
	var angle_2 = PI-center
	#print(length_to_target)
	#print(angle_2)
	
	if solvable:
		return [turn_angle,-angle_1,-angle_2]
	else:
		return null
