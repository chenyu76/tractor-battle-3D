extends Node2D

# 始终加载的场景，用于保存用户配置

# 玩家数量信息
var player_num
# 蛇的材质
var sms = [load("res://art/snake_material_1.tres"),
			load("res://art/snake_material_2.tres"),
			load("res://art/snake_material_3.tres"),
			load("res://art/snake_material_4.tres")]
# 键位
var key_sets

# 额外的模式
# 模式：fly：飞行
# 模式：fpv：玩家的第一人称视角
var extra_mode
# 是否随机抽取额外模式游玩
var random_extra_mode

# 可用的额外模式，名称：选项
const avail_mode = {
	"fly mode": "fly",
	"6 direction": "6d",
	"fpv mode": "fpv",
	"left & right": "lnr",
	"smooth rotate": "smooth_rotate",
	"car mode": "car",
	"no jump": "noj",
	"teleport": "teleport",
	"on the moon": "otm",
	"speed up": "spd",
	"snake": "snk",
	"you're small": "small",
	"you're large": "large",
	"you're huge": "huge",
	"mini map": "mini_map",
	"large map": "large_map",
	"circular map": "circular",
	"spherical map": "spherical",
	"sword": "sword",
	"hammer": "hammer",
	"quick recharge": "quick_recharge"
}
# 可用的键位配置
const avail_keyset = {
	"WASD+Q": ["w", "s", "a", "d", "q"], 
	"Arrows+Rctrl": ["up1", "down1", "left1", "right1", "Rctrl"],
	"IJKL+U": ["i", "k", "j", "l", "u"],
	"WASD+K": ["w", "s", "a", "d", "k"], 
	"Arrows+space": ["up1", "down1", "left1", "right1", "jump1"],
	"Game controller": ["joyU", "joyD", "joyL", "joyR", "joyA"]
	}
	
	
# 默认地图大小
const default_map_size = 60

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reset_config()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func reset_config():
	key_sets = []
	extra_mode = []
	random_extra_mode = false
	player_num = 2
