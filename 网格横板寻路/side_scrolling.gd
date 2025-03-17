extends TileMap

var astar := AStarGrid2D.new()
var platform_path: Array[Vector2i]
var platform_edge_path: Array[Vector2i]
var platform_down_path: Array[Vector2i]

const DOWN_POINT_WEIGHT := 10
const EDGE_POINT_WEIGHT := 10

func _ready():
	path_finder_ready()

func path_finder_ready():
	# 栅格上用来寻路的区域 = 该地图的包围矩形
	astar.region = get_used_rect()
	# 网格大小设置
	astar.cell_size = get_tileset().tile_size
	
	# 设置运动模式
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	
	update_points()

func update_points():
	# 判断可行点
	for x in range(astar.region.position.x, astar.region.end.x):
		for y in range(astar.region.position.y, astar.region.end.y):
			var coord = Vector2i(x, y)
			var tile_data := get_cell_tile_data(0, coord)
			astar.set_point_solid(coord)
			
			if tile_data and !tile_data.get_custom_data("unwalkable"):
				var down_coord = coord + Vector2i(0, 1)
				var down_tile_data := get_cell_tile_data(0, down_coord)
				if down_tile_data and down_tile_data.get_custom_data("unwalkable"):
					astar.set_point_solid(coord, false)
					platform_path.append(coord)
					# 调试显示点
					var new_point = ShowPointPath.CreatePathPoint(to_global(map_to_local(coord)), Color.AQUAMARINE)
					add_child(new_point)
	
	# 判断平台边缘点
	for point in platform_path:
		check_edge_point(point + Vector2i(-1, 0))  # 左边缘
		check_edge_point(point + Vector2i(1, 0))   # 右边缘
	
	# 生成下落点
	for edge_point in platform_edge_path:
		down_point_judge(edge_point)

func check_edge_point(point: Vector2i):
	var tile_data = get_cell_tile_data(0, point)
	if tile_data and !tile_data.get_custom_data("unwalkable"):
		var down_point = point + Vector2i(0, 1)
		var down_tile_data = get_cell_tile_data(0, down_point)
		if down_tile_data and !down_tile_data.get_custom_data("unwalkable"):
			astar.set_point_solid(point, false)
			astar.set_point_weight_scale(point, EDGE_POINT_WEIGHT)
			platform_edge_path.append(point)
			# 调试显示点
			var new_point = ShowPointPath.CreatePathPoint(to_global(map_to_local(point)), Color.BLACK)
			add_child(new_point)

func down_point_judge(point: Vector2i):
	var current_point = point
	while true:
		current_point += Vector2i(0, 1)
		if not astar.region.has_point(current_point):
			break
		
		var tile_data = get_cell_tile_data(0, current_point)
		if tile_data and !tile_data.get_custom_data("unwalkable"):
			if !platform_path.has(current_point) and !platform_edge_path.has(current_point):
				astar.set_point_solid(current_point, false)
				astar.set_point_weight_scale(current_point, DOWN_POINT_WEIGHT)
				platform_down_path.append(current_point)
				# 调试显示点
				var new_point = ShowPointPath.CreatePathPoint(to_global(map_to_local(current_point)), Color.RED)
				add_child(new_point)
			else:
				break
		else:
			break

func get_true_id_path(from_id: Vector2i, to_id: Vector2i) -> Array[Vector2i]:
	# 初始边界检查
	if not astar.region.has_point(from_id) or not astar.region.has_point(to_id):
		return []
	
	# 这里应该把空中的点都加入到可达点中的，由于没加，所以这段代码会造成额外的问题
	#if astar.is_point_solid(from_id) or astar.is_point_solid(to_id):
		#return []
	
	var new_path: Array[Vector2i] = []
	
	# 处理起点
	var true_from_id := from_id
	while astar.region.has_point(true_from_id) and astar.is_point_solid(true_from_id):
		new_path.append(true_from_id)
		true_from_id += Vector2i(0, 1)
	# 检查起点是否有效
	if not astar.region.has_point(true_from_id) or astar.is_point_solid(true_from_id):
		return []
	
	# 处理终点
	var end_path: Array[Vector2i] = []
	var true_to_id := to_id
	while astar.region.has_point(true_to_id) and astar.is_point_solid(true_to_id):
		end_path.push_front(true_to_id)
		true_to_id += Vector2i(0, 1)
	# 检查终点是否有效
	if not astar.region.has_point(true_to_id) or astar.is_point_solid(true_to_id):
		return []
	
	# 获取A*路径
	var astar_path := astar.get_id_path(true_from_id, true_to_id)
	if astar_path.is_empty():
		return []
	
	# 合并路径
	new_path += astar_path
	new_path += end_path
	
	return new_path

func get_local_pos_map_cell(pos: Vector2) -> Vector2i:
	return local_to_map(pos)

func debug_print_path(path: Array[Vector2i]):
	print(path)
	for point in path:
		var new_point = ShowPointPath.CreatePathPoint(to_global(map_to_local(point)), Color.CHOCOLATE)
		add_child(new_point)
