class_name ShowPointPath
extends Node2D

@export var color:Color = Color.AQUAMARINE

const SHOWPIONT = preload("res://横板寻路/show_path_point.tscn")

func _draw():
	draw_circle(Vector2.ZERO,5.0,color)


static func CreatePathPoint(new_position:Vector2i,color:Color = Color.AQUAMARINE)->Node2D:
	var new_point = SHOWPIONT.instantiate()
	new_point.color = color
	new_point.position = new_position
	return new_point
