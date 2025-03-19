extends Node
class_name MapPathFinder

## 适配 PVZR 项目的需求
## 1.高度设置与不可达规则更新
## 2.提供对路径的处理
	## 2.1 路径节点数量优化，保留关键节点
	## 2.2 传入传出都采取全局坐标以兼容
	## 2.3 寻路路径起点终点检查更加严格。起点、终点的映射需要单独的处理逻辑，不仅仅是水线下。
## 3.添加了一个wall-edge使之更加偏向与跟随建筑移动
## 4.添加路径缓存机制（最大 MAX_CACHE_QUEUE_SIZE 条）

const ENTITY_HEIGHT := 2
const VECTOR2I_NULL := Vector2i(-1,-1)
const MAP_TOP_Y := 0
const MAX_CACHE_QUEUE_SIZE := 50

const PLATFROM_POINT_WEIGHT := 1
const WALL_EDGE_POINT_WEIGHT := 5
const AIR_POINT_WEIGHT := 1000

@export var map:TileMapLayer
@export var cache_enabled := true  # 是否启用路径缓存

var astar := PVZRAStarGrid2D.new()
var platform_path: Array[Vector2i]
var platform_edge_path:Array[Vector2i]
var platform_down_path:Array[Vector2i]

## 存储已经验证过的出水点
var water_out_cell:Array[Vector2i] = []

## 路径缓存系统
var path_cache := {}
var cache_queue := []  # 用于维护缓存顺序

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
	clear_cache()
	for x in range(astar.region.position.x,astar.region.end.x):
		for y in range(astar.region.position.y,astar.region.end.y):
			update_one_cell(Vector2i(x,y))

func update_one_cell(cell:Vector2i):
	clear_cache()
	if is_solid_cell(cell):
		astar.set_point_solid(cell)
	elif is_platform_cell(cell):
		astar.set_point_weight_scale(cell,PLATFROM_POINT_WEIGHT)
	elif is_wall_edge_cell(cell):
		astar.set_point_weight_scale(cell,WALL_EDGE_POINT_WEIGHT)
	else:
		astar.set_point_weight_scale(cell,AIR_POINT_WEIGHT)


func get_id_path(from:Vector2i,to:Vector2i)->Array[Vector2i]:
	# 检查缓存
	if cache_enabled:
		var cached_path = get_cached_path(from, to)
		if cached_path:
			return cached_path

	if from.x <= astar.region.position.x or from.x >= astar.region.end.x:
		return []
	
	if not astar.is_in_boundsv(to):
		return []
	
	var platfrom_to:Vector2i = find_platform_tile(to)
	if platfrom_to == VECTOR2I_NULL:
		return []
	
	var path:Array[Vector2i] = []
	
	if from.y < get_top_water_cell_y():
		path.append(from)
	else:
		from = find_platform_tile(from)
	
	## 允许搜索一条不可达路径，用于冰车完全封闭路径时，但要求目标位于有效位置
	var allow_partial_path:bool = not astar.is_point_solid(platfrom_to) 
	path.append_array(astar.get_id_path(from,platfrom_to,allow_partial_path))
	path.append(to)
	
	var filtered_path = filter_path(path)
	
	# 更新缓存
	if cache_enabled:
		update_cache(from, to, filtered_path)
	
	return filtered_path

## 缓存相关方法
func get_cached_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var key = _generate_cache_key(from, to)
	var default_return :Array[Vector2i] = []
	return path_cache.get(key,default_return)

func update_cache(from: Vector2i, to: Vector2i, path: Array[Vector2i]):
	var key = _generate_cache_key(from, to)
	
	# 更新缓存队列
	if path_cache.has(key):
		cache_queue.erase(key)
	
	# 添加新条目
	path_cache[key] = path
	cache_queue.append(key)
	
	# 维护缓存大小
	while cache_queue.size() > MAX_CACHE_QUEUE_SIZE:
		var old_key = cache_queue.pop_front()
		path_cache.erase(old_key)

func _generate_cache_key(from: Vector2i, to: Vector2i) -> String:
	return "%d_%d_%d_%d" % [from.x, from.y, to.x, to.y]

func clear_cache():
	path_cache.clear()
	cache_queue.clear()

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

func find_platform_tile(input_coord: Vector2i) -> Vector2i:
	var x = input_coord.x
	var current_y = input_coord.y
	
	# 判断搜索方向
	if current_y <= get_top_water_cell_y():
		## 实体高于水线时，从当前位置向下搜索，找到第一个平台点
		for y in range(current_y, get_top_water_cell_y()):
			var coord = Vector2i(x, y)
			if is_platform_cell(coord):
				return coord
	else:
		## 实体低于水线时，向上搜索，找到上面第一个平台点
		for y in range(get_top_water_cell_y() + Vector2i.UP.y,MAP_TOP_Y,-1):
			var coord = Vector2i(x, y)
			if is_platform_cell(coord):
				return coord
	
	return VECTOR2I_NULL  # 未找到返回无效坐标

func is_platform_cell(coord: Vector2i) -> bool:
	# 1. 当前格子无瓦片
	if is_used_cell(coord):
		return false
	
	# 2. 高度要求
	for i in range(1,ENTITY_HEIGHT):
		var above = Vector2i(coord.x, coord.y - i)
		if coord.y > 0 and is_used_cell(above):
			return false

	# 3. 下方格子有瓦片，或者在水线上一格
	var below = Vector2i(coord.x, coord.y + 1)
	if not is_used_cell(below) and not coord.y + Vector2i.DOWN.y == get_top_water_cell_y():
		return false

	return true

func is_used_cell(cell:Vector2i)->bool:
	return get_used_cells().has(cell)

func is_wall_edge_cell(cell:Vector2i)->bool:
	return get_used_cells().has(cell + Vector2i.RIGHT) \
	or get_used_cells().has(cell + Vector2i.LEFT)\
	or get_used_cells().has(cell + Vector2i.DOWN + Vector2i.LEFT)\
	or get_used_cells().has(cell + Vector2i.DOWN + Vector2i.RIGHT)

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
		if water_out_cell.has(raw_path[i-1]):
			filtered.append(raw_path[i-1])
			continue
		elif raw_path[i-1].y + 1 == get_top_water_cell_y() and raw_path[i].y + 1 == get_top_water_cell_y():
			if get_used_cells().has(raw_path[i] + Vector2i.DOWN) and not get_used_cells().has(raw_path[i-1] + Vector2i.DOWN):
				water_out_cell.append(raw_path[i-1])
				filtered.append(raw_path[i-1])
				continue
	
		var current_direction := raw_path[i] - raw_path[i-1]
		# 检测到方向变化时记录转折点
		if current_direction != previous_direction:
			# 过滤掉同一竖直线上连续点的路径中间点
			if raw_path[i].x == raw_path[i-1].x and raw_path[i].x == raw_path[i-2].x:
				continue
			filtered.append(raw_path[i-1])
			previous_direction = current_direction
	
	# 确保终点始终保留
	filtered.append(raw_path[-1])
	
	return filtered
