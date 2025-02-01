extends CharacterBody2D

@export var grid:TileMap

var target_path :Array[Vector2i]
var curr_cell:Vector2i:
	get:
		return grid.get_local_pos_map_cell(position)

func _process(delta):
	move(delta)

func move(delta:float):
	if Input.is_action_just_pressed("click"):
		var mouse_position = get_global_mouse_position()
		var start_coord = curr_cell
		var target_coord = grid.local_to_map(mouse_position)
		var calculated_path = grid.get_true_id_path(start_coord,target_coord)
		if calculated_path.size() > 0:
			target_path = calculated_path
	
	fall(delta)
	if target_path and not target_path.is_empty():
		if target_path[0].y == curr_cell.y:
			plat_move(target_path[0])
		elif target_path[0].y < curr_cell.y:
			jump()
		if curr_cell == target_path[0]:
			target_path.remove_at(0)
	
	move_and_slide()



func jump(jump_cells = 1):
	if is_on_floor():
		velocity.y = -500

func fall(delta:float):
	if !is_on_floor():
		velocity.y += 98 * delta

func plat_move(next_cell):
	if next_cell.x > curr_cell.x:
		velocity.x = 100
	elif next_cell.x < curr_cell.x:
		velocity.x = -100
	else:
		velocity.x = 0
