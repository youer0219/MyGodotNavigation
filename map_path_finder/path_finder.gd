extends Node
class_name PathFinder

@export var map:TileMapLayer


var astar := AStarGrid2D.new()
var platform_path: Array[Vector2i]
var platform_edge_path:Array[Vector2i]
var platform_down_path:Array[Vector2i]


const PLATFROM_POINT_WEIGHT := 1
const AIR_POINT_WEIGHT := 100

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
			if is_used_cell(cell):
				astar.set_point_solid(cell)
			elif is_platform_cell(cell):
				astar.set_point_weight_scale(cell,PLATFROM_POINT_WEIGHT)
				var new_point = ShowPointPath.CreatePathPoint(map.to_global(map.map_to_local(cell)),Color.BLACK)
				add_child(new_point)
			else:
				astar.set_point_weight_scale(cell,AIR_POINT_WEIGHT)
				var new_point = ShowPointPath.CreatePathPoint(map.to_global(map.map_to_local(cell)),Color.ALICE_BLUE)
				add_child(new_point)

func get_id_path(from:Vector2i,to:Vector2i)->Array[Vector2i]:
	if astar.is_in_bounds(to.x,to.y):
		return astar.get_id_path(from,to)
	return []

func is_used_cell(cell:Vector2i)->bool:
	return get_used_cells().has(cell)

func is_platform_cell(cell:Vector2i)->bool:
	return not get_used_cells().has(cell) and get_used_cells().has(cell + Vector2i.DOWN)

func get_used_cells()->Array[Vector2i]:
	return map.get_used_cells_by_id(0,Vector2i(1,1),0)
