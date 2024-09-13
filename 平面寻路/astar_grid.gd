extends TileMap

var astar := AStarGrid2D.new()


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
	
	for x in range(astar.region.position.x,astar.region.end.x):
		for y in range(astar.region.position.y,astar.region.end.y):
			var coord = Vector2i(x,y)
			for layer in get_layers_count():
				var tile_data := get_cell_tile_data(layer,coord)
				if tile_data and tile_data.get_custom_data("unwalkable"):
					astar.set_point_solid(coord)
