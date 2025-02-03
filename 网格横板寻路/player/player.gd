extends CharacterBody2D

@export var grid:TileMap
@export var speed:int = 60

var target_path :Array[Vector2i]
var curr_cell:Vector2i:
	get:
		return grid.get_local_pos_map_cell(position)

func _process(delta):
	do_find_path()
	move(delta)

func move(delta:float):
	fall(delta)
	if target_path:
		print(target_path)
	if target_path and not target_path.is_empty():
		
		plat_move(target_path[0])
		
		if target_path[0].y < curr_cell.y and is_on_floor():
			var jump_cells:int = abs(target_path[0].y - curr_cell.y)
			for num in range(target_path.size()):
				if num == 0:
					continue
				if target_path[num].y < target_path[num-1].y:
					print("(abs(target_path[num].y - target_path[0].y) + 1: ",(abs(target_path[num].y - target_path[0].y) + 1))
					jump_cells = abs(target_path[num].y - target_path[0].y) + 1
				else:
					break
			print("jump_cells: ",jump_cells)
			jump(jump_cells)
		
		if curr_cell == target_path[0] and target_path.size() > 1:
			target_path.remove_at(0)
		
		if target_path.size() == 1:
			if abs(position.x - map_to_local(target_path[0]).x) < 1 and target_path[0].y == curr_cell.y:
				target_path.remove_at(0)
				velocity.x = 0
	
	move_and_slide()

func do_find_path():
	if Input.is_action_just_pressed("click"):
		var mouse_position = get_global_mouse_position()
		var start_coord = curr_cell
		var target_coord = grid.local_to_map(mouse_position)
		var calculated_path = grid.get_true_id_path(start_coord,target_coord)
		if calculated_path.size() > 0:
			target_path = calculated_path
			print("target_path: ",target_path)

func jump(jump_cells = 1):
	# 计算所需跳跃高度（像素）
	var jump_height = 16 * (jump_cells) * 1.1  # 1.2倍余量保证跨格
	
	# 根据自由落体公式计算初速度：v0 = sqrt(2 * g * h)
	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	var initial_velocity := -sqrt(2 * gravity * jump_height)
	velocity.y = initial_velocity

func fall(delta:float):
	if !is_on_floor():
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta

func plat_move(next_cell:Vector2i):
	var next_pos := map_to_local(next_cell)
	var direction:Vector2 = Vector2.ZERO
	
	if next_pos.x - 1> position.x:
		direction.x = 1
	elif next_pos.x + 1 < position.x:
		direction.x = -1
	
	if direction:
		velocity.x = direction.x * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

func map_to_local(cell:Vector2i)->Vector2:
	return grid.map_to_local(cell)
