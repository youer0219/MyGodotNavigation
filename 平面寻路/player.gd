extends Sprite2D

@export var grid:TileMap

var target_path :Array[Vector2i]

func _process(delta):
	if Input.is_action_just_pressed("click"):
		var mouse_position = get_global_mouse_position()
		
		# 如果中途切换终点，判断是否已有路径，如果已有且长度大于1，则以该路径的第一个点为起点，否则以当前位置为起点
		# 避免切换终点时，玩家回退到上一格
		var start_coord = target_path[0] if target_path and target_path.size() > 0 else grid.local_to_map(global_position)
		var target_coord = grid.local_to_map(mouse_position)
		
		# 避免点击无效位置导致寻路失效
		var calculated_path = grid.astar.get_id_path(start_coord,target_coord)
		if calculated_path.size() > 0:
			target_path = calculated_path
	
	# 如果路径存在且不为空，开始寻路
	if target_path and not target_path.is_empty():
		var target_position = grid.map_to_local(target_path[0])
		global_rotation = global_position.direction_to(target_position).angle() # 转向
		global_position = global_position.move_toward(target_position,100 * delta)
		
		if global_position == target_position:
			target_path.remove_at(0)
