extends CharacterBody3D

# 蛇的速度
@export var speed = 20
# 蛇的跳跃高度
@export var jump_impulse = 8
# 蛇的（默认/计算时使用的）重力加速度
@export var default_fall_acceleration = 20
var fall_acceleration = default_fall_acceleration

#@export var snake_body_scene: PackedScene

# 蛇的长度（尺寸），以每节碰撞箱为单位元
var snake_size = 5000
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
# 也可以作为Vector3.UP使用，这样在飞行模式时可兼容其他模式
var velocity_above = Vector3.UP
# 飞行模式的旋转速度
var fly_rotation_speed = 3

# 六方向模式，使用飞行模式的部分选项
var d6_mode = false

# 方向键的左右是旋转模式
var lnr_mode = false

# 禁止跳跃
var no_jump = false

# 像蛇一样的摆动模式
var _snake_process = func(): pass

# 剑模式： 按功能键摆动武器 的函数
var _sword_process = func(_d): pass

# 锤子模式： 按功能键锤下
var _hammer_process = func(_d): pass

# 顺滑的旋转 模式
# 使用旋转速度的和飞行模式的旋转速度相同 fly_rotation_speed
# 使用的加速机制和 lnr 相同
var smooth_rotate_mode = false

# 上次记录的位置，用于控制创建碰撞箱的时机，离远了就创建
var last_position

# 汽车模式 按键才移动
var _car_mode_process = func(_d): pass
var car_mode = false
var car_mode_acceleration = 2

# 仅当可控制为true时可接收玩家操作
var controllable = true

# 是否创建碰撞箱
var create_collision_boxes = true

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
	if 'quick_recharge' in Config.extra_mode:
		default_power_generate_speed *= 5		
		power_generate_speed = default_power_generate_speed

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
	
	# 初始化上次的位置
	last_position = position
	
	# 处理其他玩法
	if '6d' in extra_mode:
		d6_mode = true
		fly_mode = true
	# 飞行模式
	if 'fly' in extra_mode or fly_mode:
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
	if 'snk' in extra_mode:
		_snake_process = func(): 
			velocity = velocity.rotated(velocity_above, sin(Time.get_ticks_msec() / 50.0) / 2.0)
	if 'sword' in extra_mode:
		$pivot/sword.visible = true
		$pivot/sword/CollisionShape3D.disabled = false
		$pivot/sword/MeshInstance3D.set_surface_override_material(0, snake_material)
		_sword_process = func(d): 
			if Input.is_action_pressed(key_set[4]):
				$pivot/sword.rotation = Vector3(0, sin(Time.get_ticks_msec() / 50.0) , 0)
				power -= d * 3
			else:
				$pivot/sword.rotation = Vector3.ZERO
	else:
		$pivot/sword.visible = false
		$pivot/sword/CollisionShape3D.disabled = true
	if 'hammer' in extra_mode:
		$pivot/hammer.visible = true
		$pivot/hammer/CollisionShape3D.disabled = false
		$pivot/hammer/I.set_surface_override_material(0, snake_material)
		$pivot/hammer/O.set_surface_override_material(0, snake_material)
		_hammer_process = func(d): 
			if Input.is_action_pressed(key_set[4]):
				if $pivot/hammer.rotation.x > 0:
					$pivot/hammer.rotation -= Vector3(d * PI/2 * 3 * scale.x , 0, 0)
					$pivot/hammer.scale += Vector3.ONE * d * 3 * scale.x 
				power -= d * 25
			else:
				$pivot/hammer.rotation = Vector3(PI/2, 0, 0)
				$pivot/hammer.scale = Vector3.ONE / 100
	else:
		$pivot/hammer.visible = false
		$pivot/hammer/CollisionShape3D.disabled = true
	if 'smooth_rotate' in extra_mode:
		smooth_rotate_mode = true
		lnr_mode = true
	if 'car' in extra_mode:
		car_mode = true
		_car_mode_process = func(delta):
			if (func():
				for i in range(5):
					if Input.is_action_pressed(key_set[i]):
						return true
				return false  # 有任意按键按下返回 true，否则返回false
				).call():
				if speed_multiplier <= 1.5:
					speed_multiplier += delta * car_mode_acceleration
			else:
				if speed_multiplier > delta * car_mode_acceleration + 1.0/speed:
					speed_multiplier -= delta * car_mode_acceleration
	
func _physics_process(delta):	
	if position.y <= -10:
		die()
	if died:
		return
		
	# 更新相机位置（因为subviwport无法移动）
	$SubViewport/Camera3D.global_transform = $pivot/CamPos.global_transform
	
	if controllable:
		# 根据使用模式的不同使用不同的变向策略
		if fly_mode:
			fly_mode_process(delta)
		else:
			normal_mode_process(delta)
	
	# 处理奇怪模式的函数调用
	_snake_process.call()
	_sword_process.call(delta)
	_hammer_process.call(delta)
	_car_mode_process.call(delta)
	
	move_and_slide()
	
	# 如果不是car_mode 那撞停了就可以直接死了
	if (not died) and (not car_mode) and (Abs(velocity) == 0)  :
		die()

	# 当离碰撞箱远了，创建新的身体碰撞箱
	if Abs(position - last_position) > 0.6:
		if create_collision_boxes:
			generate_body()
		last_position = position
	
	# 可能需要调整点的数量或对路径进行平滑处理以保持性能和视觉效果
	# 创建新的蛇身点
	# 创建新身体渲染
	build_snake_body((now_direction + Vector3(0, sin(rotation_x), 0)).normalized())
	

# 删除所有的身体渲染
func delete_snake_body():
	get_parent().remove_child(mesh_instance)

# 创建新的身体碰撞箱
func generate_body():
	if Abs(velocity) > 0.01: # 防止除0
		var body = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		body.disabled = true
		shape.size = Vector3(1, 1, 0.5)
		body.shape = shape
		body.global_transform = self.global_transform
		body.rotation = $pivot.rotation
		$SubViewport/BodyContainer.add_child(body)
		await get_tree().create_timer(2 / Abs(velocity)).timeout
		body.disabled = false

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
	var right = direction.cross(velocity_above.rotated(direction, speed_up_ani_angle)).normalized() * size
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
	if d6_mode: # 6 direction mode
		if Input.is_action_just_pressed(key_set[0]):
			var temp = direction
			direction = - velocity_above
			velocity_above = temp.normalized()
		if Input.is_action_just_pressed(key_set[1]):
			var temp = direction
			direction = velocity_above
			velocity_above = - temp.normalized()
		if Input.is_action_just_pressed(key_set[2]):
			direction = nor
		if Input.is_action_just_pressed(key_set[3]):
			direction = - nor
	else: # fly mode
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
	
	velocity = direction.normalized() * speed * speed_multiplier
	now_direction = direction.normalized()
	head_direction = (2 * head_direction + now_direction).normalized()
	
	# 如果d6_mode有方向输入，创建几个平滑过渡 有bug，先不启用
	if false and direction.dot(velocity) == 0 and speed_multiplier <= 1: 
		var num = 5 # 过渡数量
		for i in range(num):
				build_snake_body( (direction * i + velocity * (num - 1 - i)).normalized() )
	
	# 防止撞到什么东西速度更新了但指向上方的向量没更新
	if velocity.dot(velocity_above) != 0:
		var v = -velocity.cross(velocity_above).cross(velocity).normalized()
		if v.dot(velocity_above) > 0:
			velocity_above = v
		else:
			velocity_above = -v
	
	$pivot.look_at_from_position(position, position + head_direction, velocity_above)
	
func normal_mode_process(delta):
	var direction = Vector3.ZERO
	var target_velocity = velocity
	target_velocity.x = 0
	target_velocity.z = 0
	# 不是飞行模式，使用正常玩法
	# 改变方向
	
	# 左右旋转模式
	if smooth_rotate_mode:
		# 按下一直转 smooth_rotate_mode
		if Input.is_action_pressed(key_set[2]):
			now_direction = velocity.rotated(Vector3.UP, delta * fly_rotation_speed).normalized()
		if Input.is_action_pressed(key_set[3]):
			now_direction = velocity.rotated(Vector3.UP, -delta * fly_rotation_speed).normalized()

	elif allow_key_input:
		if not lnr_mode:
			# 正常模式
			if Input.is_action_pressed(key_set[0]):
				direction.z -= 1
			if Input.is_action_pressed(key_set[1]):
				direction.z += 1
			if Input.is_action_pressed(key_set[2]):
				direction.x -= 1
			if Input.is_action_pressed(key_set[3]):
				direction.x += 1
		else:
			# 按下转 90 度 left and right
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
			if speed_multiplier <= 1:
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
		# 左右转的模式的加速
		if Input.is_action_pressed(key_set[0]) and speed_multiplier <= 2:
			speed_multiplier += 2*delta
		if Input.is_action_pressed(key_set[1]) and speed_multiplier >= 0.5:
			speed_multiplier -= 2*delta
		power -= max(power_needed_to_speed_up * delta * (speed_multiplier-1), 0)
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

# 计算Vector3的绝对值（长度）
func Abs(vec):
	return sqrt(vec.x*vec.x + vec.y*vec.y + vec.z*vec.z)
