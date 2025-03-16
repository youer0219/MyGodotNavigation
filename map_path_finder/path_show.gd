extends Node2D
class_name PathShow


@export var map:TileMapLayer


func clear():
	for child in get_children():
		child.queue_free()


func show_path(cells:Array[Vector2i]):
	clear()
	
	for cell in cells:
		var new_point = ShowPointPath.CreatePathPoint(map.to_global(map.map_to_local(cell)),Color.RED)
		new_point.z_index = 100
		add_child(new_point)	





#
