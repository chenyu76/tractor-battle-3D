extends Node3D

@export var snake_head_scene: PackedScene

# 用于存储实例化的蛇
var snakes = []

# 总共的蛇数量
const snake_num = 30

# 目前使用的蛇编号,在snake_num中来回使用
var order = 0

# 屏幕四个顶点在3d空间中的位置，通过calc_screen_edges计算，[[左上， 右上],[左下,右下]]
# screen_vertex_position
var svp = []

# 距离上一次转向过了多久
var since_last_rotation = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	snakes.resize(snake_num)
	calc_screen_edges()
	generate_lots_of_snakes()

func generate_lots_of_snakes():
	for i in range(20):
		_on_generate_timer_timeout()
		await get_tree().create_timer(0.1).timeout

# 计算相机中的3D平面对应的位置
func calc_screen_edges():
	#var cam = $SubViewport/Camera3D
	var cam = $SubViewport/Camera3D
	# 地平面高度
	var h = 2
	# 相机高度
	var h_cam = cam.position.y
	
	var lu = cam.project_ray_normal(Vector2(0, 0))
	var rl = cam.project_ray_normal($SubViewport.size)
	
	var lu3 = Vector3(lu.x * (h_cam - h)/lu.y, h, lu.z * (h_cam - h)/lu.y)
	var rl3 = Vector3(rl.x * (h_cam - h)/rl.y, h, rl.z * (h_cam - h)/rl.y)
	
	var ll3 = Vector3(lu3.x, h, rl3.z)
	var ru3 = Vector3(rl3.x, h, lu3.z)

	svp = [[lu3, ru3], [ll3, rl3]]
	return

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	since_last_rotation += delta
	if since_last_rotation > 0.05:
		_on_rotate_timer_timeout()
		since_last_rotation -= 0.05

func generate_snake(index):
	if snakes[index]: # 如何这条蛇已经存在，删除它
		snakes[index].delete_snake_body()
		remove_child(snakes[index])
		snakes[index].queue_free()
	# 实例化新的蛇
	snakes[index] = snake_head_scene.instantiate()
	
	# 计算需要在哪里生成蛇
	var vo = []
	vo.resize(4)
	while true:
		for i in range(4):
			vo[i] = randi_range(0, 1)
		if  (not vo[0] ^ vo[2]) or (not vo[1] ^ vo[3]):
			break
	# 位于 边界的 比例
	var r = randf_range(0, 1)
	# 一个随机的边界位置
	var p = svp[vo[0]][vo[1]] * r + svp[vo[2]][vo[3]] * (1 - r)
	#var p = Vector3(randf_range(-40, 40), 1, randf_range(-40, 40))
	# 面向中心的横纵向方向
	var d = (func():
			var direction = [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]
			var result = [0, direction[0]]
			for di in direction:
				if (-p).dot(di) > result[0]:
					result = [(-p).dot(di), di]
			return result[1]
			).call()
	# 将位置稍作偏移，防止蛇在边界直接刷新
	p -= 2*d
	# 让位置上下浮动
	p.y += randi_range(0, 3) * 1.1

	snakes[index].position = p
	snakes[index].get_node("pivot").look_at_from_position(Vector3.ZERO, d)
	snakes[index].controllable = false
	snakes[index].create_collision_boxes = false
	snakes[index].velocity = d * 20
	snakes[index].now_direction = d # 渲染身体的方向是跟着now_direction走的
	snakes[index].initialize(index, Config.sms[randi_range(0, len(Config.sms)-1)])
	add_child(snakes[index])

# 每隔一段时间生成一条蛇穿过屏幕
func _on_generate_timer_timeout() -> void:
	generate_snake(order)
	
	# 蛇生成完毕，在下次调用时处理下一条
	order += 1
	if order >= snake_num:
		order = 0

# 让随机一条蛇旋转方向
func _on_rotate_timer_timeout() -> void:
	#$RotateTimer.wait_time = randf_range(0.1, 0.5)
	var r = randi_range(0, snake_num - 1)
	if snakes[r] and !snakes[r].died:
		var degree = randi_range(-1, 1) * PI / 2
		var d = snakes[r].now_direction.rotated(Vector3.UP, degree)
		snakes[r].velocity = d * 20
		snakes[r].get_node("pivot").look_at_from_position(snakes[r].position, snakes[r].position+d)
		#snakes[r].head_direction = d
		snakes[r].now_direction = d
