extends Node3D

# 玩家id,只能接受来自符合id的信号
var id = -1

const total_bar_length = 25
const total_power = 100.0


# var snake_material = load("res://art/snake_material_1.tres")

func initialize(id_t, snake_material = load("res://art/snake_material_1.tres")):
	id = id_t
	print("new status bar " + str(id))
	$powerBar.mesh = BoxMesh.new()
	$powerBar.mesh.size.x = 5
	$powerBar.set_surface_override_material(0, snake_material)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func update_power(power_t):
	show_power(power_t)

# 输入指定的能量数值，改变powerbar将其显示出来
func show_power(power_t):
	$powerBar.mesh.size.z = power_t / total_power * total_bar_length
	$powerBar.position.z = (1 - power_t / total_power) * total_bar_length / 2.0 
