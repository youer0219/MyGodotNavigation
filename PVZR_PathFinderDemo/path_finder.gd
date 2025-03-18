extends Node
class_name PathFinder

## TODO: 适配 PVZR 项目的需求
## 1.高度设置与不可达规则更新(OK)
## 2.提供对路径的处理
	## 2.1 路径节点数量优化，保留关键节点
	## 2.2 传入传出都采取全局坐标以兼容
	## 2.3 寻路路径起点终点检查更加严格。起点、终点的映射需要单独的处理逻辑，不仅仅是水线下。
## 3.特殊：对于“水线”下的节点，将其映射到第一个平台点上进行寻路(OK)
## 4.添加了一个wall-edge使之更加偏向与跟随建筑移动

const ENTITY_HEIGHT := 2
const VECTOR2I_NULL := Vector2(-1,-1)
const MAP_HEIGHT := 24

const PLATFROM_POINT_WEIGHT := 1
const WALL_EDGE_POINT_WEIGHT := 10
const AIR_POINT_WEIGHT := 20


@export var map:TileMapLayer

var astar := AStarGrid2D.new()
var platform_path: Array[Vector2i]
var platform_edge_path:Array[Vector2i]
var platform_down_path:Array[Vector2i]

func _ready():
	path_finder_ready()

func path_finder_ready():
	# 栅格上用来寻路的区域 = 该地图的包围矩形，包围所有图层中的已使用（非空）的图块。
	astar.region = map.get_used_rect()
	# 网格大小设置
	astar.cell_size = map.tile_set.tile_size
	
	# 使其不再允许对角线穿过，而是直线运动
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	# 更新AStarGrid2D以准备搜索路径
	astar.update()
	
	update_points()

func update_points():
	for x in range(astar.region.position.x,astar.region.end.x):
		for y in range(astar.region.position.y,astar.region.end.y):
			var cell := Vector2i(x,y)
			if is_solid_cell(cell):
				astar.set_point_solid(cell)
			elif is_platform_cell(cell):
				astar.set_point_weight_scale(cell,PLATFROM_POINT_WEIGHT)
				var new_point = ShowPointPath.CreatePathPoint(map.to_global(map.map_to_local(cell)),Color.BLACK)
				add_child(new_point)
			elif is_wall_edge_cell(cell):
				astar.set_point_weight_scale(cell,WALL_EDGE_POINT_WEIGHT)
				var new_point = ShowPointPath.CreatePathPoint(map.to_global(map.map_to_local(cell)),Color.RED)
				add_child(new_point)
			else:
				astar.set_point_weight_scale(cell,AIR_POINT_WEIGHT)
				var new_point = ShowPointPath.CreatePathPoint(map.to_global(map.map_to_local(cell)),Color.ALICE_BLUE)
				add_child(new_point)

func get_id_path(from:Vector2i,to:Vector2i)->Array[Vector2i]:
	
	if from.x < astar.region.position.x or from.x > astar.region.end.x:
		return []
	
	if to.x < astar.region.position.x or to.x > astar.region.end.x:
		return []
	
	## 在水线下时，需要讲from映射到第一个顶部的空位置。
	if from.y >= get_top_water_cell_y():
		from = get_first_top_empty_cell(from)
	
	if astar.is_in_bounds(to.x,to.y):
		return astar.get_id_path(from,to)
	return []

func is_solid_cell(cell:Vector2i)->bool:
	## 禁止水线下的点
	if cell.y >= get_top_water_cell_y():
		return true
	## 地形限制
	if get_used_cells().has(cell):
		return true
	## 高度限制
	if get_used_cells().has(cell + Vector2i.DOWN):
		for height in range(1,ENTITY_HEIGHT):
			if get_used_cells().has(cell + Vector2i.UP * (height)):
				return true
	
	return false

func get_first_top_empty_cell(cell:Vector2i)->Vector2i:
	for top_cell_y in range(1,MAP_HEIGHT):
		var new_cell := cell - Vector2i(0,top_cell_y)
		if new_cell.y >= get_top_water_cell_y():
			continue
		if not astar.is_in_boundsv(new_cell):
			continue
		if get_used_cells().has(new_cell):
			continue
		return new_cell
	
	return VECTOR2I_NULL

func is_used_cell(cell:Vector2i)->bool:
	return get_used_cells().has(cell)

func is_platform_cell(cell:Vector2i)->bool:
	if cell.y + 1 == get_top_water_cell_y():
		return true
	
	return not get_used_cells().has(cell) and get_used_cells().has(cell + Vector2i.DOWN)

func is_wall_edge_cell(cell:Vector2i)->bool:
	return get_used_cells().has(cell + Vector2i.RIGHT) or get_used_cells().has(cell + Vector2i.LEFT)

func get_used_cells()->Array[Vector2i]:
	return map.get_used_cells()

func get_top_water_cell_y()->int:
	return 16

func filter_path(raw_path: Array[Vector2i]) -> Array[Vector2i]:
	# 处理空路径和简单路径的情况
	if raw_path.size() <= 2:
		return raw_path.duplicate()
	
	var filtered :Array[Vector2i] = [raw_path[0]]  # 起点必须保留
	var previous_direction := raw_path[1] - raw_path[0]
	
	# 遍历路径寻找方向变化的关键点
	for i in range(2, raw_path.size()):
		
		# 检测出水点 
		if raw_path[i-1].y + 1 == get_top_water_cell_y() and raw_path[i].y + 1 == get_top_water_cell_y():
			if get_used_cells().has(raw_path[i] + Vector2i.DOWN) and not get_used_cells().has(raw_path[i-1] + Vector2i.DOWN):
				filtered.append(raw_path[i-1])
				continue
	
		var current_direction := raw_path[i] - raw_path[i-1]
		# 检测到方向变化时记录转折点
		if current_direction != previous_direction:
			filtered.append(raw_path[i-1])
			previous_direction = current_direction
	
	# 确保终点始终保留
	filtered.append(raw_path[-1])
	
	return filtered
