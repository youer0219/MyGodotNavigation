extends CharacterBody2D

@export var grid:TileMap

var target_path :Array[Vector2i]
var curr_cell:Vector2i:
	get:
		return grid.get_local_pos_map_cell(position)

func _process(delta):
	#if Input.is_action_just_pressed("click"):
		#var mouse_position = get_global_mouse_position()
		#
		## 如果中途切换终点，判断是否已有路径，如果已有且长度大于1，则以该路径的第一个点为起点，否则以当前位置为起点
		## 避免切换终点时，玩家回退到上一格
		#var start_coord = target_path[0] if target_path and target_path.size() > 0 else grid.local_to_map(global_position)
		#var target_coord = grid.local_to_map(mouse_position)
		#
		## 避免点击无效位置导致寻路失效
		#var calculated_path = grid.get_true_id_path(start_coord,target_coord)
		#if calculated_path.size() > 0:
			#target_path = calculated_path
	
	## 如果路径存在且不为空，开始寻路
	#if target_path and not target_path.is_empty():
		#var target_position = grid.map_to_local(target_path[0])
		#rotation = position.direction_to(target_position).angle() # 转向
		#position = position.move_toward(target_position,100 * delta)
		#
		#if position == target_position:
			#print(grid.get_local_pos_map_cell(position))
			#target_path.remove_at(0)
	print(curr_cell)
	print(target_path)
	move(delta)

func move(delta:float):
	if Input.is_action_just_pressed("click"):
		var mouse_position = get_global_mouse_position()
		var start_coord = curr_cell
		var target_coord = grid.local_to_map(mouse_position)
		var calculated_path = grid.get_true_id_path(start_coord,target_coord)
		if calculated_path.size() > 0:
			target_path = calculated_path
	
	fall()
	if target_path and not target_path.is_empty():
		if target_path[0].y == curr_cell.y:
			plat_move(target_path[0])
		elif target_path[0].y > curr_cell.y:
			jump()
		
	move_and_slide()
	
	if target_path and not target_path.is_empty():
		if curr_cell == target_path[0]:
			target_path.remove_at(0)


func jump(jump_cells = 1):
	if is_on_floor():
		velocity.y = -500

func fall():
	if !is_on_floor():
		velocity.y = 100

func plat_move(next_cell):
	if next_cell.x > curr_cell.x:
		velocity.x = 100
	elif next_cell.x < curr_cell.x:
		velocity.x = -100
	else:
		velocity.x = 0
