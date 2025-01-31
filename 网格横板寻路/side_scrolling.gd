extends TileMap

var astar := AStarGrid2D.new()
var platform_path: Array[Vector2i]
var platform_edge_path:Array[Vector2i]
var platform_down_path:Array[Vector2i]

func _ready():
	# 栅格上用来寻路的区域 = 该地图的包围矩形，包围所有图层中的已使用（非空）的图块。
	astar.region = get_used_rect()
	# 网格大小设置
	astar.cell_size = get_tileset().tile_size
	
	# 使其不再允许对角线穿过，而是直线运动
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	# 更新AStarGrid2D以准备搜索路径
	astar.update()
	
	# 判断可行点
	for x in range(astar.region.position.x,astar.region.end.x):
		for y in range(astar.region.position.y,astar.region.end.y):
			# 默认全部不可达
			var coord = Vector2i(x,y)
			var tile_data := get_cell_tile_data(0,coord)
			astar.set_point_solid(coord)
			# 判断哪些可达
			if tile_data and !tile_data.get_custom_data("unwalkable"):
				var down_coord = coord + Vector2i(0,1)
				var down_tile_data := get_cell_tile_data(0,down_coord)
				if down_tile_data and down_tile_data.get_custom_data("unwalkable"):
					astar.set_point_solid(coord,false)
					platform_path.append(coord)
					var new_point = ShowPointPath.CreatePathPoint(to_global(map_to_local(coord)),Color.AQUAMARINE)
					add_child(new_point)
	
	# 判断平台边缘的地点
	for point in platform_path:
		var left_point = point + Vector2i(-1,0)
		var right_point = point + Vector2i(1,0)
		
		var left_point_tile_data = get_cell_tile_data(0,left_point)
		if left_point_tile_data and !left_point_tile_data.get_custom_data("unwalkable"):
			var left_down_point = left_point + Vector2i(0,1)
			var left_down_point_tile_data = get_cell_tile_data(0,left_down_point)
			if left_down_point_tile_data and !left_down_point_tile_data.get_custom_data("unwalkable"):
				astar.set_point_solid(left_point,false)
				var new_point = ShowPointPath.CreatePathPoint(to_global(map_to_local(left_point)),Color.BLACK)
				add_child(new_point)
				platform_edge_path.append(left_point)
		
		var right_point_tile_data = get_cell_tile_data(0,right_point)
		if right_point_tile_data and !right_point_tile_data.get_custom_data("unwalkable"):
			var right_down_point = right_point + Vector2i(0,1)
			var right_down_point_tile_data = get_cell_tile_data(0,right_down_point)
			if right_down_point_tile_data and !right_down_point_tile_data.get_custom_data("unwalkable"):
				astar.set_point_solid(right_point,false)
				var new_point = ShowPointPath.CreatePathPoint(to_global(map_to_local(right_point)),Color.BLACK)
				add_child(new_point)
				platform_edge_path.append(right_point)
	
	# 生成落下时的点
	for edge_point in platform_edge_path:
		down_point_judge(edge_point)
	
	get_true_id_path(Vector2i(3,5),Vector2i(-5,-4))

func down_point_judge(point:Vector2i):
	var down_point = point + Vector2i(0,1)
	var down_point_tile_data = get_cell_tile_data(0,down_point)
	
	if down_point_tile_data and !down_point_tile_data.get_custom_data("unwalkable"):
		if !platform_path.has(down_point) and !platform_edge_path.has(down_point):
			astar.set_point_solid(down_point,false)
			var new_point = ShowPointPath.CreatePathPoint(to_global(map_to_local(down_point)),Color.RED)
			add_child(new_point)
			platform_down_path.append(down_point)
			down_point_judge(down_point)


## 目前基本可行，但还是没有理想效果……
func get_true_id_path(from_id: Vector2i, to_id: Vector2i)->Array[Vector2i]:
	var new_path:Array[Vector2i]
	
	# 判断起点位置 如果在不是平台边的空中，就向下找合适的点位
	var true_from_id:Vector2i = from_id
	while astar.is_point_solid(true_from_id):
		new_path.append(true_from_id)
		true_from_id = true_from_id + Vector2i(0,1)
	
	# 判断终点位置 如果在空中，需要找到其下的平台位置
	var end_path:Array[Vector2i]
	var true_to_id = to_id
	while astar.is_point_solid(true_to_id):
		end_path.push_front(true_to_id)
		true_to_id = true_to_id + Vector2i(0,1)
	
	new_path += astar.get_id_path(true_from_id,true_to_id) + end_path
	#print(new_path)
	return new_path
