extends Node3D

@export var snake_head_scene: PackedScene
@export var snake_status_scene: PackedScene

# 重启游戏的信号，发送的id是败者的id
signal restart(id)

# 游戏是否结束
var game_ended = false
# 败者的id
var loser
# 败者死亡时的位置
var loser_position
# 结算时旋转的朝向方向
var forward_vector = -transform.basis.y
# 结算动画播放时间达到后设为true,使动画不运动
var ended_ani = false

# 玩家数量信息
var player_num = 2
	
# 蛇
var snakes = []
# 蛇的能量条
var infos = []
# 蛇的材质
var sms = [load("res://art/snake_material_1.tres"),
			load("res://art/snake_material_2.tres")]
# 键位
var key_sets = [["w", "s", "a", "d", "k"], 
				["up1", "down1", "left1", "right1", "jump1"]]
				
var snake_positions = build_snake_position(player_num)
var status_positions = build_snake_status_position(player_num)

# Called when the node enters the scene tree for the first time.
func _ready():
	MusicPlayer.play()
	for i in range(player_num):
		
		snakes.push_back(snake_head_scene.instantiate())
		infos.push_back(snake_status_scene.instantiate())
	start_game()
	
func _physics_process(delta):
	if game_ended:
		if !ended_ani:
			var target_p = loser_position + Vector3(0,3,0)
			var speed = $Marker3D.position.distance_to(target_p) * delta * 0.5
			$Marker3D.position += $Marker3D.position.direction_to(target_p) * speed
			
			var toward = $Marker3D.position.direction_to(loser_position)
			forward_vector = (forward_vector + toward * delta).normalized()
			$Marker3D.look_at($Marker3D.position + forward_vector, Vector3.UP)
			
			$Marker3D/Camera.fov += 3 * delta
			
		if Input.is_action_just_pressed("r"):
			# 发送重启信号到MainWithScore
			restart.emit(loser)

# 将蛇节点添加到子节点，开始游戏
func start_game():
	for i in range(player_num):
		snakes[i].position = snake_positions[i]
		snakes[i].initialize(i, sms[i], key_sets[i])
		add_child(snakes[i])
		
		infos[i].position = status_positions[i]
		infos[i].initialize(i, sms[i])
		add_child(infos[i])
		#if i == 0:
		snakes[i].update_power_info.connect(infos[i].show_power.bind())
		snakes[i].hit.connect(snake_die.bind())

func snake_die(id, snake_position):
	if !game_ended:
		game_ended = true
		loser_position = snake_position
		loser = id
		$losePivot/lose.set_surface_override_material(0, sms[id])
		$losePivot/lose.set_surface_override_material(1, sms[id])
		#$losePivot.look_at($Marker3D.position, Vector3.UP)
		$losePivot.position = loser_position + Vector3(0,3,0)
		$loseAniTimer.start()
		MusicPlayer.stop()
		$loseMusic.play()
		#$losePivot.scale = Vector3(0.1,0.1,0.1)
	print("player " + str(id) + " hit at " + str(snake_position))


# 输入snake数量，返回每个snake应该放哪的vector3 array
func build_snake_position(num):
	var array = []
	array.resize(num)
	var map_length = 60
	for i in range(num):
		array[i] = Vector3(map_length / (num + 1.0) * (i+1) - map_length / 2.0, 2, 0)
	return array
	
# 输入snake数量，返回每个snake的状态栏应该放哪的vector3 array
func build_snake_status_position(num):
	var array = []
	array.resize(num)
	for i in range(num):
		var l_r = 40
		if i%2 == 0:
			l_r = -40
		array[i] = Vector3(l_r, 0, 0)
	return array



func _on_lose_ani_timer_timeout():
	ended_ani = true
