extends Control

var wait_logo = true

# Called when the node enters the scene tree for the first time.
func _ready():
	$unity.position = get_viewport_rect().size / 2
	$unity/TextureRect.position = -get_viewport_rect().size / 2
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("r"):
		get_tree().change_scene_to_file("res://start.tscn")
	if !wait_logo:
		$unity.rotation += 0.5
		$unity.position.x -= 10
		$unity.position.y += 2
	


func _on_static_timer_timeout():
	wait_logo = false


func _on_end_timer_timeout():
	get_tree().change_scene_to_file("res://start.tscn")
