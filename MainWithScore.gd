extends Node3D

# 玩家数量信息，会从main.gd里同步
var player_num = 0
# 已经死的玩家id列表
var die_players = []

# 每个玩家的得分，需要初始化为零
var score = []
# 显示在屏幕上的得分板
var score_label = []

# 游戏主场景
@export var main_scene: PackedScene
var Main

# 重启时的信号
signal restart_game()

# Called when the node enters the scene tree for the first time.
func _ready():
	# 实例化main场景
	start_main_scene()
	
	for i in range(player_num):
		score.push_back(0)
		# 创建分数文本mesh
		score_label.push_back(MeshInstance3D.new())
		score_label[i].position = Main.status_positions[i] + Vector3(0,0,12)
		score_label[i].rotation.x = -PI/2
		score_label[i].mesh = TextMesh.new()
		score_label[i].mesh.text = "0"
		score_label[i].mesh.depth = 0.5
		score_label[i].mesh.font_size = 256
		score_label[i].scale = Vector3(2,2,2)
		score_label[i].set_surface_override_material(0, Main.sms[i])
		
		# 创建score字样mesh
		var score_text = MeshInstance3D.new()
		score_text.position = Main.status_positions[i] + Vector3(0,0,14)
		score_text.rotation.x = -PI/2
		score_text.mesh = TextMesh.new()
		score_text.mesh.text = "Score"
		score_text.mesh.depth = 1
		score_text.mesh.font_size = 96
		score_text.set_surface_override_material(0, Main.sms[i])
		add_child(score_text)
		
		add_child(score_label[i])
		
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_main_restart(id):
	# 重置场景
	Main.queue_free()
	start_main_scene()
	#update_score(id)
	
	# 发送重启游戏信号	
	restart_game.emit()
	
func start_main_scene():
	if Config.random_extra_mode:
		random_extra_mode()
	Main = main_scene.instantiate()
	player_num = Main.player_num
	die_players = []
	add_child(Main)
	Main.restart.connect(_on_main_restart.bind())
	for i in range(player_num):
		Main.snakes[i].hit.connect(update_score.bind())
	#Main.get_node("SubViewport/Camera").current = true
	
# 输入败者id,更新其他蛇id的计分板上的分数，各加一
func update_score(id, _pos=Vector3.ZERO):
	#print("Update score")
	#游戏没结束才能加分
	if player_num - len(die_players) > 1:
		die_players.push_back(id)
		for i in range(player_num):
			if i != id and (i not in die_players):
				score[i] += 1
				score_label[i].mesh.text = str(score[i])
				print("\tplayer "+str(i) + " score: " + str(score[i]))

func random_extra_mode():
	# 抽取的模式数量， 不宜太多
	var exnum = int(1.0 / randi_range(0, len(Config.avail_mode) - 1))
	var values_array = Config.avail_mode.values()
	Config.extra_mode = []
	while Config.extra_mode.size() < exnum:
		var random_value = values_array[randi() % values_array.size()]
		if not random_value in Config.extra_mode:
			Config.extra_mode.append(random_value)
		
