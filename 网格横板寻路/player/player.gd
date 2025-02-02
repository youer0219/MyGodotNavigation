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

	if target_path and not target_path.is_empty():
		
		plat_move(target_path[0])
		
		if target_path[0].y < curr_cell.y:
			jump()
		
		if curr_cell == target_path[0] and target_path.size() > 1:
			target_path.remove_at(0)
		
		if target_path.size() == 1:
			if abs(position.x - map_to_local(target_path[0]).x) < 1:
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

func jump(jump_cells = 1):
	if is_on_floor():
		velocity.y = -400

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
