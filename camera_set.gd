extends Node2D

# 放置不同相机的2d界面集合

var fpv_mode = false
var player_num = 0
# 用于储存玩家的相机的窗口rect
var players_cam = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 将重玩信号连接到相机
	$MainWithScore.restart_game.connect(restart.bind())
	
	# 检查有几个玩家
	player_num = Config.player_num
	# 检查是否需要第一人称视角
	if "fpv" in Config.extra_mode:
		fpv_mode = true
		players_cam.resize(player_num)
		# 添加视角
		for i in range(player_num):
			players_cam[i] = TextureRect.new()
			add_child(players_cam[i])
			players_cam[i].visible = true
	
	get_window().size_changed.connect(_on_window_size_changed.bind())
	bind_camera()
	_on_window_size_changed()
	
func restart():
	fpv_mode = "fpv" in Config.extra_mode
	bind_camera()
	rechange_view()
	_on_window_size_changed()
	
func rechange_view():
	# 检查是否需要第一人称视角
	if fpv_mode:
		for i in players_cam:
			i.visible = true
	else:
		for i in players_cam:
			i.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	#for i in range(player_num):
		#$MainWithScore.Main.snakes[i].get_node("SubViewport").position += Vector3(delta, 0, 0)

# 把相机连接到矩形
func bind_camera():
	if fpv_mode:
		for i in range(player_num):
			players_cam[i].texture = $MainWithScore.Main.snakes[i].get_node("SubViewport").get_texture()
	# 修改材质为相机画面
	$MainWindow.texture = $MainWithScore.Main.get_node("SubViewport").get_texture()


func _on_window_size_changed():
	if fpv_mode: #第一人称模式，需要根据玩家数量放置对应的摄像机视角数量
		var window_size = get_window().size
		var p_cam_size = Vector2(window_size.x/player_num, window_size.y / 2)
		for i in range(player_num):
			$MainWithScore.Main.snakes[i].get_node("SubViewport").set_size(p_cam_size)
			players_cam[i].set_size(p_cam_size)
			players_cam[i].position = Vector2(window_size.x * i / player_num, 0)
		
		var main_cam_size = Vector2(window_size.x, window_size.y / 2)
		$MainWithScore.Main.get_node("SubViewport").set_size(main_cam_size)
		$MainWindow.set_size(main_cam_size)
		$MainWindow.position = Vector2(0, window_size.y/2)
	else: #只有一个主窗口
		# 获取新的窗口大小
		var new_window_size = get_window().size
		
		# 调整 TextureRect 的尺寸
		$MainWindow.set_size(new_window_size)
		$MainWindow.position = Vector2.ZERO
	
		# 调整相机分辨率
		$MainWithScore.Main.get_node("SubViewport").set_size(new_window_size)
