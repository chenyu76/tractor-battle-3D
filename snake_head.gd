extends CharacterBody3D

# 蛇的速度
@export var speed = 20
# 蛇的跳跃高度
@export var jump_impulse = 8
# 蛇的（默认/计算时使用的）重力加速度
@export var default_fall_acceleration = 20
var fall_acceleration = default_fall_acceleration

@export var snake_body_scene: PackedScene

# 蛇的长度
var snake_length = 5000
# 蛇的移动方向
var now_direction = Vector3.FORWARD
# 蛇的头朝向的方向，由于动画需要，head_direction不会渐变
var head_direction = Vector3.FORWARD
# 蛇竖直方向的旋转
var rotation_x = 0

# 用于操作的按键集
var key_set
var allow_key_input = true

# 蛇的颜色
var snake_material

# 撞到东西死了（要表明死的哪条蛇），以及广播死亡位置，播放结算动画
signal hit(snake, positio)
# 蛇是否已死亡
var died = false

# 能量，每次跳跃或加速都需要能量
var power = 100
const power_needed_to_jump = 15
const power_needed_to_speed_up = 33
# 让游戏界面更新能量信息
signal update_power_info(p)

# id,用于鉴别这是哪条蛇，在初始化时需要提供
var id = 1

# 创建蛇身网格
var curve_path: Curve3D
var mesh_instance: MeshInstance3D
# 顶点与法向
var vertices = PackedVector3Array()
var normals = PackedVector3Array()
# square vertices 先前的正方形 网格节点
var svp
var sv

# 四个方向上双击按键的状态，松开后如果一段时间没有再按下重置为0
# 0: 没按过
# 1: 刚按下
# 2: 刚松开
# 3: 按了第二次
var double_click_button = 0
var double_click_status = 0
# 加速时会乘这个数
var speed_multiplier = 1
# 加速时使用的螺旋动画变量
var speed_up_ani_angle = 0.0

# (默认及使用的)获得/丢失能量的速度，在移动到屏幕外时会变为负数
@export var default_power_generate_speed = 0.25
var power_generate_speed = default_power_generate_speed

# 使用飞行模式
var fly_mode = false
# 与速度垂直，指向上方的向量，用于在飞行模式中判断方向
var velocity_above = Vector3.UP
# 飞行模式的旋转速度
var fly_rotation_speed = 3

# 方向键的左右是旋转模式
var lnr_mode = false

# 禁止跳跃
var no_jump = false

# 第一人称视角
# 发送自己的SubViewport 的 Camera path 和 id ， fpv会接收并显示出来
#signal head_camera_id(path, id)

func _ready():
	curve_path = Curve3D.new()
	mesh_instance = MeshInstance3D.new()
	add_sibling(mesh_instance)
	#mesh_instance.mesh = ArrayMesh.new()
	curve_path.add_point(position)
	curve_path.add_point(position)
	var direction = head_direction + Vector3(0, sin(rotation_x), 0)
	svp = create_square_at_point(curve_path.get_point_position(0), direction, 0.5) # 假定大小为0.5
	sv = create_square_at_point(curve_path.get_point_position(1), direction, 0.5) # 假定大小为0.5
	
	if 'otm' in Config.extra_mode:
		fall_acceleration = default_fall_acceleration / 6.0

func initialize(id_t, 
		snake_material_t = load("res://art/snake_material_1.tres"), 
		key_set_t = ["up1", "down1", "left1", "right1", "jump1"],
		extra_mode = []):
	snake_material = snake_material_t
	key_set = key_set_t
	id = id_t
	print("new snake " + str(id))
	for i in range(0,7):
		$pivot/MeshInstance3D.set_surface_override_material(i, snake_material)
	
	allow_key_input = true
	#$generateBodyTimer.start()
	$input_interval.wait_time = 1.0 / speed
	
	# 处理其他玩法
	# 飞行模式
	if 'fly' in extra_mode:
		fly_mode = true
		fall_acceleration = 0
		velocity = Vector3(0, 0, -speed)
	else:
		fall_acceleration = default_fall_acceleration
	if 'lnr' in extra_mode:
		lnr_mode = true
	if 'noj' in extra_mode:
		no_jump = true
	if 'spd' in extra_mode:
		speed = 40
		
func _physics_process(delta):	
	if position.y <= -10:
		die()
	if died:
		return
		
	# 更新相机位置（因为subviwport无法移动）
	$SubViewport/Camera3D.global_transform = $pivot/CamPos.global_transform
		
	
	# 根据使用模式的不同使用不同的变向策略
	if fly_mode:
		fly_mode_process(delta)
	else:
		normal_mode_process(delta)
		
	move_and_slide()
	
	# 创建新的身体碰撞箱
	generate_body()
	
	# 可能需要调整点的数量或对路径进行平滑处理以保持性能和视觉效果
	# 创建新的蛇身点
	# 创建新身体渲染
	build_snake_body((now_direction + Vector3(0, sin(rotation_x), 0)).normalized())
	

# 创建新的身体箱
func generate_body():
	#print("new body")
	var body = snake_body_scene.instantiate()
	body.initialize(id, now_direction, rotation_x, snake_length / float(speed))
	body.get_node("CollisionShape3D").disabled = true
	body.position = self.position
	#mob.squashed.connect($UserInterface/ScoreLabel._on_mob_squashed.bind())
	hit.connect(body._on_snake_head_hit.bind())
	await get_tree().create_timer(1.5 / speed).timeout
	
	add_sibling(body)


func _on_input_interval_timeout():
	allow_key_input = true


func _on_collision_detector_body_entered(_body):
	die()

func _on_visible_on_screen_notifier_3d_screen_exited():
	#print("离开屏幕")
	power_generate_speed = -8 * default_power_generate_speed
	
func _on_visible_on_screen_notifier_3d_screen_entered():
	power_generate_speed = default_power_generate_speed

	
func die():
	#$pivot/collisionDetector/CollisionShape3D.disabled = true
	if !died:
		died = true
		#print("player " + str(id) + " hit!")
		hit.emit(id, position)
		speed = 0
		jump_impulse = 0
		$powerGenerator.stop()
	# queue_free()


func _on_power_generator_timeout():
	if power < 99.9 or power_generate_speed < 0:
		power += power_generate_speed
		if power > 100:
			power = 100
	update_power_info.emit(power)
	
	# 当能量为负数时死亡
	if power < -0.5:
		#print("死于出界")
		die()
		
func create_square_at_point(point_position: Vector3, direction: Vector3, size: float) -> Array:
	var vertices2 = []
	#有加速时修改方向
	if speed_multiplier > 1:
		speed_up_ani_angle += PI / 10
	var right = direction.cross(Vector3.UP.rotated(direction, speed_up_ani_angle)).normalized() * size
	var up = right.cross(direction).normalized() * size

	# 计算正方形的四个顶点
	vertices2.append(point_position + right + up)
	vertices2.append(point_position + right - up)
	vertices2.append(point_position - right - up)
	vertices2.append(point_position - right + up)

	return vertices2

# 创建新身体渲染
func build_snake_body(direction):
	curve_path.add_point(position)

	# 对于Curve3D上的点，创建正方形并添加到网格
	var i = curve_path.get_point_count() - 1
	
	svp = sv
	sv = create_square_at_point(curve_path.get_point_position(i), direction, 0.5) # 假定大小为0.5
	
	for j in range(4):
		# 这里添加正方形顶点到SurfaceTool，并创建面
		
		# 第一个三角形
		vertices.push_back(svp[(j + 1)%4])
		vertices.push_back(svp[j])
		vertices.push_back(sv[j])
		
		# 计算法线
		var edge2 = svp[(j + 1)%4] - sv[j]
		var edge1 = svp[j] - sv[j]
		var normal = edge1.cross(edge2).normalized()
		
		# 由于三角形共面，三个顶点可以共享相同的法线
		normals.push_back(normal)
		normals.push_back(normal)
		normals.push_back(normal)
		
		# 第二个三角形
		vertices.push_back(sv[j])
		vertices.push_back(sv[(j + 1)%4])
		vertices.push_back(svp[(j + 1)%4])
		
		# 计算法线
		edge2 = sv[(j + 1)%4] - sv[j]
		edge1 = svp[(j + 1)%4] - sv[j]
		normal = edge1.cross(edge2).normalized()
		
		normals.push_back(normal)
		normals.push_back(normal)
		normals.push_back(normal)
	
	# 初始化 ArrayMesh。
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals

	# 创建 Mesh。
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = arr_mesh
	mesh_instance.set_surface_override_material(0, snake_material)
	
	

# 双击按键超时后清空按键状况
func _on_double_click_timer_timeout():
	double_click_status = 0


func _on_speed_up_timer_timeout():
	speed_multiplier = 1
	speed_up_ani_angle = 0.0

func fly_mode_process(delta):
	# 离远了会掉血
	power -= max(abs(position.x) + abs(position.y) + abs(position.z) - 80, 0) * delta
	var direction = velocity
	# 0 1 2 3
	# 上下左右
	var nor = velocity_above.cross(velocity).normalized()
	var fs = delta * fly_rotation_speed

	if Input.is_action_pressed(key_set[0]):
		direction = direction.rotated(nor, fs)
		velocity_above = velocity_above.rotated(nor, fs)
	if Input.is_action_pressed(key_set[1]):
		direction = direction.rotated(nor, -fs)
		velocity_above = velocity_above.rotated(nor, -fs)
	if Input.is_action_pressed(key_set[2]):
		# 这是真正的旋转，但是没有第一人称视角会很奇怪
		#direction = velocity.rotated(velocity_above, fs) 
		if velocity_above.dot(Vector3.UP) >= 0:
			fs *= -1
		direction = direction.rotated(Vector3.UP, -fs)
		velocity_above = velocity_above.rotated(Vector3.UP, -fs)
	if Input.is_action_pressed(key_set[3]):
		#direction = velocity.rotated(velocity_above, -fs)
		if velocity_above.dot(Vector3.UP) >= 0:
			fs *= -1
		direction = direction.rotated(Vector3.UP, fs)
		velocity_above = velocity_above.rotated(Vector3.UP, fs)
	if direction != velocity:

		velocity = direction.normalized() * speed
		now_direction = direction.normalized()
		head_direction = direction.normalized()
		
		$pivot.look_at_from_position(position, position + head_direction, velocity_above)
	#print(velocity)
	
func normal_mode_process(delta):
	var direction = Vector3.ZERO
	var target_velocity = velocity
	target_velocity.x = 0
	target_velocity.z = 0
	# 不是飞行模式，使用正常玩法
	# 改变方向
	if allow_key_input:
		if not lnr_mode:
			if Input.is_action_pressed(key_set[0]):
				direction.z -= 1
			if Input.is_action_pressed(key_set[1]):
				direction.z += 1
			if Input.is_action_pressed(key_set[2]):
				direction.x -= 1
			if Input.is_action_pressed(key_set[3]):
				direction.x += 1
		else:
			if Input.is_action_just_pressed(key_set[2]):
				direction = velocity.rotated(Vector3.UP, PI/2)
			if Input.is_action_just_pressed(key_set[3]):
				direction = velocity.rotated(Vector3.UP, -PI/2)
		# 输入的方向需要不是反方向
		if direction != Vector3.ZERO and direction.dot(now_direction) >= -0.1:
			allow_key_input = false
			$input_interval.start()
			
			direction = direction.normalized()
			
			# 在没有加速时，渲染几个身体外观，使过渡圆滑
			if speed_multiplier == 1:
				# 过渡数量
				var num = 5
				for i in range(num):
					build_snake_body(( (direction * i + now_direction * (num - 1 - i) ) 
										+ Vector3(0, sin(rotation_x), 0)).normalized())
				
			now_direction = direction
			
	if not lnr_mode:
		# 双击按键加速
		for i in range(4):
			if double_click_status == 0 and Input.is_action_just_pressed(key_set[i]):
				double_click_button = i
				double_click_status = 1
				break
		if double_click_status == 1 and Input.is_action_just_released(key_set[double_click_button]):
			double_click_status = 2
			$doubleClickTimer.start()
		if double_click_status == 2 and Input.is_action_just_pressed(key_set[double_click_button]) \
				and power > power_needed_to_speed_up and speed_multiplier == 1:
			speed_multiplier = 2
			double_click_status = 0
			$speedUpTimer.start()
			power -= power_needed_to_speed_up
	else:
		power -= power_needed_to_speed_up * delta * (speed_multiplier-1)
		if Input.is_action_pressed(key_set[0]) and speed_multiplier <= 2:
			speed_multiplier += 2*delta
		if Input.is_action_pressed(key_set[1]) and speed_multiplier >= 0.85:
			speed_multiplier -= 2*delta
	# Ground Velocity
	target_velocity.x = now_direction.x * speed * speed_multiplier
	target_velocity.z = now_direction.z * speed * speed_multiplier
	
	# Vertical Velocity
	if not is_on_floor(): # If in the air, fall towards the floor. Literally gravity
		target_velocity.y -= (fall_acceleration * delta)
		# print("v:" + str(target_velocity) + "\t l:" + str(position)) 
		
	# 跳跃 Jumping. 需要power_needed_to_jump点能量
	# 在no jump 为true 时不允许跳跃
	if (!no_jump) and power > power_needed_to_jump and Input.is_action_just_pressed(key_set[4]) and is_on_floor(): 
			target_velocity.y = jump_impulse if speed_multiplier==1 else 2*jump_impulse
			power -= power_needed_to_jump
	
	#if Input.is_action_pressed(key_set[4]) and target_velocity.y > 0 and not is_on_floor(): 
		#target_velocity.y = 3 * jump_impulse
	
	# 竖直方向上的旋转
	rotation_x = max(-PI*2/5, PI / 4 * velocity.y / jump_impulse)
	
	velocity = target_velocity
	
	head_direction = (2 * head_direction + now_direction).normalized()
	$pivot.look_at_from_position(position, position + head_direction, Vector3.UP)
	$pivot.rotation.x = rotation_x
