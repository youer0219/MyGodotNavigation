extends Node2D
class_name PathShowExecutor


var enable:bool = true:set = _set_enable
var path_requester_id:EncodedObjectAsID = null
var paths:Array[Vector2] = []
var path_color:Color = Color.ALICE_BLUE
var path_circle_radius:float = 1.0


func _draw() -> void:
	if enable:
		for path_point in paths:
			draw_circle(path_point,path_circle_radius,path_color)

func update_path():
	queue_redraw()

func _set_enable(value:bool):
	enable = value
	queue_redraw()
