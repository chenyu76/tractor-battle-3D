extends Node2D



# Called when the node enters the scene tree for the first time.
func _ready():
	
	get_window().size_changed.connect(_on_window_size_changed.bind())
	_on_window_size_changed()
	
	# 切换额外模式的按钮配置
	var container = $Container/eModeContainer  # 确保你已经创建了一个 VBoxContainer 节点来容纳按钮
	for button_name in Config.avail_mode.keys():
		var button = Button.new()
		button.text = button_name
		button.toggle_mode = true  # 设置按钮为切换模式
		#button.add_theme_color_override("icon_pressed_color", Color.AQUA)
		button.add_theme_color_override("font_pressed_color", Color.AQUA)
		var expression = Expression.new()
		#expression.parse("button.button_down.connect((func():Config.extra_mode.append("+avail_mode[button_name]+")).bind())")
		#expression.parse("button.button_up.connect((func():Config.extra_mode.erase("+avail_mode[button_name]+")).bind())")
		button.toggled.connect((func(pressed):
			if pressed:
				Config.extra_mode.append(Config.avail_mode[button_name])
			else:
				Config.extra_mode.erase(Config.avail_mode[button_name])
			print("extra mode enabled: " + var_to_str(Config.extra_mode))
			).bind())
		#button.button_up.connect((func():Config.extra_mode.erase(avail_mode[button_name])).bind())
		container.add_child(button)
	
	# 提供切换键位选项
	renewPlayerNum(2)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_button_pressed():
	get_tree().change_scene_to_file("res://camera_set.tscn")

# 减少一个玩家
func _on_minus_button_down() -> void:
	if Config.player_num==1:
		return
	Config.player_num-=1
	renewPlayerNum(Config.player_num)
# 增加一个玩家
func _on_plus_button_down() -> void:
	if Config.player_num==4:
		return
	Config.player_num+=1
	renewPlayerNum(Config.player_num)
func renewPlayerNum(n):
	Config.key_sets.resize(n)
	$Container/playerNumContainer/Label.text = var_to_str(n)
	playerKeyset(n)

func _on_window_size_changed():
	var sz = get_window().size
	$Container.set_size(Vector2(sz.x / 10, sz.y))
	$Container.position = Vector2(sz.x / 2 - sz.x / 10, 0)

# 创建一个修改玩家键位的控件
func playerKeyset(num):
	var keyCtrl = $Container/playerKeyContainer
	for child in keyCtrl.get_children():
		keyCtrl.remove_child(child)
	var keys_array = Config.avail_keyset.values()
	for i in range(num):
		var container = HBoxContainer.new()
		var label = Label.new()
		label.text = "P" + var_to_str(i+1)
		var option = OptionButton.new()
		# 设置下拉框选项
		for key in Config.avail_keyset.keys():
			option.add_item(key)
		# 设置默认键位
		Config.key_sets[i] = keys_array[0]
		# 连接信号
		option.item_selected.connect((func(j):
			Config.key_sets[i] = keys_array[j]
			print("Players key set: " + var_to_str(Config.key_sets))
			).bind())
		container.add_child(label)
		container.add_child(option)
		keyCtrl.add_child(container)
	


func _on_random_mode_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		$Container/ModeSelctLabel.visible = false
		$Container/eModeContainer.visible = false
		Config.random_extra_mode = true
	else:
		$Container/ModeSelctLabel.visible = true
		$Container/eModeContainer.visible = true
		Config.random_extra_mode = false
