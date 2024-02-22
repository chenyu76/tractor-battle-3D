extends RigidBody3D

signal waitingDie
signal waitingCollisionShape

var is_snake_tail = 0

# 这段身体属于哪条蛇
var id = -1

func _ready():
	$CollisionShape3D.disabled = true

func initialize(id_t, direction, rotation_x, snake_length):
	rotation.y = direction.signed_angle_to(Vector3.FORWARD, Vector3.DOWN)
	$CollisionShape3D.rotation.x = rotation_x 
	#self.look_at(position + direction, Vector3.UP)
	#$CollisionShape3D.disabled = false
	$dieTimer.wait_time = (snake_length - 1) / 2.0
	id = id_t


func _physics_process(delta):
	if is_snake_tail:
		queue_free()



func _on_collision_shape_timer_timeout():
	$CollisionShape3D.disabled = false


func _on_die_timer_timeout():
	is_snake_tail = true
	$CollisionShape3D.disabled = true
	
func _on_snake_head_hit(id_t, posi):
	if id == id_t:
		pass
		#queue_free()
