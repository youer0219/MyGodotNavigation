class_name TileMapPathFind
extends TileMap

class PointInfo:
	var isFallTile:bool
	var isLeftEdge:bool
	var isRightEdge:bool
	var isLeftWall:bool
	var isRightWall:bool
	var isPositionPoint:bool
	var PointID:int
	var Position:Vector2
	
	static func createPointInfo(pointID:int,position:Vector2i)->PointInfo:
		var new_point_info = PointInfo.new()
		new_point_info.PointID = pointID
		new_point_info.Position = position
		return new_point_info

class Stack:
	var _stack = []  # 使用数组来存储堆栈的元素
	var count:int:
		get:
			return _stack.size()
	# 将元素压入堆栈
	func push(element):
		_stack.append(element)

	# 从堆栈中弹出元素
	func pop():
		if not is_empty():
			return _stack.pop_back()
		else:
			return null  # 如果堆栈为空，则返回null

	# 查看堆栈顶部的元素
	func peek():
		if not is_empty():
			return _stack[_stack.size() - 1]
		else:
			return null

	# 检查堆栈是否为空
	func is_empty():
		return _stack.size() == 0

	# 获取堆栈的大小
	func size():
		return _stack.size()

@export var ShowDebugGraph:bool = true
@export var JumpDistance:int = 5
@export var JumpHeight:int = 4
const COLLISION_LAYER = 0
const CELL_IS_EMPTY = -1
const MAX_TILE_FALL_SCAN_DEPTH = 500
const VECTOR2I_NULL = Vector2i(-10008,-10008)

var _astarGraph:AStar2D = AStar2D.new()
var _usedTiles:Array[Vector2i]
var _graphpoint:PackedScene
var _pointInfoList:Array[PointInfo]

func _ready():
	
	_graphpoint = preload("res://基于B站视频的横板寻路/Scenes/TileMapPathFind/GraphPoint.tscn")
	_usedTiles = get_used_cells(COLLISION_LAYER)
	
	BuildGraph()

func BuildGraph():
	AddGraphPoints()
	
	if !ShowDebugGraph:
		ConnectPoints()

func GetPointInfoAtPosition(position:Vector2)->PointInfo:
	var newInfoPoint = PointInfo.createPointInfo(-10000,position)
	var tile = local_to_map(position)
	newInfoPoint.isPositionPoint = true
	
	if !TileEmpty(tile+Vector2i(0,1)):
		if !TileEmpty(tile+Vector2i(-1,0)):
			newInfoPoint.isLeftWall = true
		if !TileEmpty(tile+Vector2i(1,0)):
			newInfoPoint.isRightWall = true
		if !TileEmpty(tile+Vector2i(-1,1)):
			newInfoPoint.isLeftEdge = true
		if !TileEmpty(tile+Vector2i(1,1)):
			newInfoPoint.isRightEdge = true
	return newInfoPoint 

func ReversePathStack(pathStack:Stack)->Stack:
	var pathStackReversed:Stack = Stack.new()
	while pathStack.count != 0:
		pathStackReversed.push(pathStack.pop())
	return pathStackReversed

func GetPlaform2DPath(startPos:Vector2,endPos:Vector2)->Stack:
	var pathStack = Stack.new()
	
	var idPath = _astarGraph.get_id_path(_astarGraph.get_closest_point(startPos),_astarGraph.get_closest_point(endPos))
	
	if idPath.size() <= 0:return pathStack
	
	var startPoint = GetPointInfoAtPosition(startPos)
	var endPoint = GetPointInfoAtPosition(endPos)
	var numPointsInPath = idPath.size()
	
	for i in numPointsInPath:
		var currPoint = FilterListByID(idPath[i])
		#pathStack.push(currPoint)
		
		if numPointsInPath == 1:
			continue
		
		if i == 0 && numPointsInPath >= 2:
			var secondPathPoint = FilterListByID(idPath[i+1])
			
			if startPoint.Position.distance_to(secondPathPoint.Position) < currPoint.Position.distance_to(secondPathPoint.Position):
				pathStack.push(startPoint)
				continue
		elif i == numPointsInPath - 1 && numPointsInPath >= 2:
			var penultimatePoint = FilterListByID(idPath[i - 1])
			
			if endPoint.Position.distance_to(penultimatePoint.Position) < currPoint.Position.distance_to(penultimatePoint.Position):
				continue
			else:
				pathStack.push(currPoint)
				break
		pathStack.push(currPoint)
	pathStack.push(endPoint)
	return ReversePathStack(pathStack)

func DrawDebugLine(to:Vector2,from:Vector2,color:Color):
	if ShowDebugGraph:
		draw_line(from,to,color)
		queue_redraw()

func AddGraphPoints():
	
	for tile in _usedTiles:
		AddLeftEdgePoint(tile)
		AddRightEdgePoint(tile)
		AddLeftWallPoint(tile)
		AddRightWallPoint(tile)
		AddFallPoint(tile)
	

# 判断一个局部坐标是否在图中
func TileAlreadyExistInGraph(tile:Vector2i)->int:
	var localPos = map_to_local(tile)
	
	if (_astarGraph.get_point_count() > 0):
		var pointId = _astarGraph.get_closest_point(localPos)
		
		if _astarGraph.get_point_position(pointId) == localPos:
			return pointId
	
	return -1

# 显示【点】
func AddVisualPoint(tile:Vector2i,color:Color = Color.ALICE_BLUE ,scale:float = 1.0):
	if !ShowDebugGraph:
		return
	
	var visualPoint:Sprite2D = _graphpoint.instantiate() as Sprite2D
	visualPoint.modulate = color
	if scale != 1.0 && scale > 0.1:
		visualPoint.scale = Vector2(scale,scale)
	
	visualPoint.position = map_to_local(tile)
	add_child(visualPoint)

func GetPointInfo(tile:Vector2i)->PointInfo:
	for point_info in _pointInfoList:
		if point_info.Position == map_to_local(tile):
			return point_info
	return null

func _draw():
	if ShowDebugGraph:
		ConnectPoints()

#region 连接水平点

func ConnectPoints():
	for p1 in _pointInfoList:
		ConnectHorizontalPoints(p1)
		ConnectJumpPoints(p1)
		ConnectFallPoints(p1)

func ConnectFallPoints(p1:PointInfo):
	if p1.isLeftEdge || p1.isRightEdge:
		var tilePos = local_to_map(p1.Position)
		tilePos.y += 1
		
		var fallPoint:Vector2i = FindFallPoint(tilePos)
		if fallPoint != VECTOR2I_NULL:
			var pointInfo = GetPointInfo(fallPoint)
			var p2Map:Vector2 = local_to_map(p1.Position)
			var p1Map:Vector2 = local_to_map(pointInfo.Position)
			
			if p1Map.distance_to(p2Map) <= JumpHeight:
				_astarGraph.connect_points(p1.PointID,pointInfo.PointID)
				DrawDebugLine(p1.Position,pointInfo.Position,Color(0,1,0,1))
			else:
				_astarGraph.connect_points(p1.PointID,pointInfo.PointID,false)
				DrawDebugLine(p1.Position,pointInfo.Position,Color(1,1,0,1))
				

func ConnectJumpPoints(p1:PointInfo):
	for p2 in _pointInfoList:
		ConnectHorizontalPlatformJumps(p1,p2)
		ConnectDiagonalJumpRightEdgeToLeftEdge(p1,p2)
		ConnectDiagonalJumpLeftEdgeToRightEdge(p1,p2)
		

func ConnectDiagonalJumpRightEdgeToLeftEdge(p1:PointInfo,p2:PointInfo):
	if p1.isRightEdge:
		var p1Map:Vector2 = local_to_map(p1.Position)
		var p2Map:Vector2 = local_to_map(p2.Position)
		
		if p2.isLeftEdge && p2.Position.x > p1.Position.x && p2.Position.y > p1.Position.y && p2Map.distance_to(p1Map) < JumpDistance:
			_astarGraph.connect_points(p1.PointID,p2.PointID)
			DrawDebugLine(p1.Position,p2.Position,Color(0,1,0,1))

func ConnectDiagonalJumpLeftEdgeToRightEdge(p1:PointInfo,p2:PointInfo):
	if p1.isLeftEdge:
		var p1Map:Vector2 = local_to_map(p1.Position)
		var p2Map:Vector2 = local_to_map(p2.Position)
		
		if p2.isRightEdge && p2.Position.x < p1.Position.x && p2.Position.y > p1.Position.y && p2Map.distance_to(p1Map) < JumpDistance:
			_astarGraph.connect_points(p1.PointID,p2.PointID)
			DrawDebugLine(p1.Position,p2.Position,Color(0,1,0,1))

func ConnectHorizontalPlatformJumps(p1:PointInfo,p2:PointInfo):
	if p1.PointID == p2.PointID:return
	
	if p2.Position.y == p1.Position.y && p1.isRightEdge && p2.isLeftEdge:
		if p2.Position.x > p1.Position.x:
			var p2Map:Vector2 = local_to_map(p2.Position)
			var p1Map:Vector2 = local_to_map(p1.Position)
			
			if p2Map.distance_to(p1Map) < JumpDistance + 1:
				_astarGraph.connect_points(p1.PointID,p2.PointID)
				DrawDebugLine(p1.Position,p2.Position,Color(0,1,0,1))

func ConnectHorizontalPoints(p1:PointInfo):
	if p1.isLeftEdge || p1.isLeftWall || p1.isFallTile:
		var closest:PointInfo = null
		
		for p2 in _pointInfoList:
			if p1.PointID == p2.PointID:continue
			if (p2.isRightEdge || p2.isRightWall || p2.isFallTile) && p2.Position.y == p1.Position.y && p2.Position.x > p1.Position.x:
				if closest == null:
					closest = PointInfo.createPointInfo(p2.PointID,p2.Position)
				if p2.Position.x < closest.Position.x:
					closest.Position = p2.Position
					closest.PointID = p2.PointID
		
		if closest != null:
			if !HorizontalConnectionCannotBeMade(Vector2i(p1.Position),Vector2i(closest.Position)):
				_astarGraph.connect_points(p1.PointID,closest.PointID)
				DrawDebugLine(p1.Position,closest.Position,Color(0,1,0,1))

func HorizontalConnectionCannotBeMade(p1:Vector2i,p2:Vector2i)->bool:
	var startScan = local_to_map(p1)
	var endScan = local_to_map(p2)
	
	for i in range(startScan.x,endScan.x):
		if !TileEmpty(Vector2i(i,startScan.y)) || TileEmpty(Vector2i(i,startScan.y + 1)):
			return true
	return false

#endregion

#region 【坠落点】生成
# 返回值为0时意味着其不是边缘点，即原视频中的null
func GetStartScanTileForFallPoint(tile:Vector2i)->Vector2i:
	var tileAbove = tile + Vector2i(0,-1)
	var point = GetPointInfo(tileAbove)
	
	if point == null:return VECTOR2I_NULL
	
	var tileScan = VECTOR2I_NULL
	
	if point.isLeftEdge:
		tileScan = tile + Vector2i(-1,-1)
	elif point.isRightEdge:
		tileScan = tile + Vector2i(1,-1)
	return tileScan

func FindFallPoint(tile:Vector2i)->Vector2i:
	var scan = GetStartScanTileForFallPoint(tile)
	if scan == VECTOR2I_NULL :
		return VECTOR2I_NULL
	
	var tileScan:Vector2i = scan
	var fallTile:Vector2i = VECTOR2I_NULL
	for i in MAX_TILE_FALL_SCAN_DEPTH:
		if !TileEmpty(tileScan + Vector2i(0,1)):
			fallTile = tileScan
			break
		tileScan.y += 1
	return fallTile

func AddFallPoint(tile:Vector2i):
	var fallTile:Vector2i = FindFallPoint(tile)
	if fallTile == VECTOR2I_NULL :return
	var fallTileLocal = Vector2i(map_to_local(fallTile))
	
	var existingPointId = TileAlreadyExistInGraph(fallTile)
	
	if existingPointId == -1:
		var pointId:int = _astarGraph.get_available_point_id()
		var pointInfo = PointInfo.createPointInfo(pointId,fallTileLocal)
		pointInfo.isFallTile = true
		_pointInfoList.append(pointInfo)
		_astarGraph.add_point(pointId,fallTileLocal)
		AddVisualPoint(fallTile,Color(1,0.35,0.1,1),0.35)
	else:
		FilterListByID(existingPointId).isFallTile = true
		AddVisualPoint(fallTile,Color("#ef7d57"),0.3)

#endregion

#region  【边缘/墙壁点】的生成
# 添加【左边缘点】
func AddLeftEdgePoint(tile:Vector2i):
	if TileAboveExist(tile):
		return
	
	if TileEmpty(tile + Vector2i(-1,0)):
		var tileAbove = Vector2i(0,-1) + tile
		var existingPointId:int = TileAlreadyExistInGraph(tileAbove)
		
		if existingPointId == -1: # 如果这个点没有添加，就添加为【左边缘点】
			var pointId:int = _astarGraph.get_available_point_id()
			var pointInfo = PointInfo.createPointInfo(pointId,Vector2i(map_to_local(tileAbove)))
			pointInfo.isLeftEdge = true
			_pointInfoList.append(pointInfo)
			_astarGraph.add_point(pointId,Vector2i(map_to_local(tileAbove)))
			AddVisualPoint(tileAbove)
		else:
			FilterListByID(existingPointId).isLeftEdge = true
			AddVisualPoint(tileAbove,Color("#73eff7"))
# 添加【右边缘点】
func AddRightEdgePoint(tile:Vector2i):
	if TileAboveExist(tile):
		return
	
	if TileEmpty(tile + Vector2i(1,0)):
		var tileAbove = Vector2i(0,-1) + tile
		var existingPointId:int = TileAlreadyExistInGraph(tileAbove)
		
		if existingPointId == -1: # 如果这个点没有添加，就添加为【左边缘点】
			var pointId:int = _astarGraph.get_available_point_id()
			var pointInfo = PointInfo.createPointInfo(pointId,Vector2i(map_to_local(tileAbove)))
			pointInfo.isRightEdge = true
			_pointInfoList.append(pointInfo)
			_astarGraph.add_point(pointId,Vector2i(map_to_local(tileAbove)))
			AddVisualPoint(tileAbove,Color("#94b0c2"))
		else:
			FilterListByID(existingPointId).isRightEdge = true
			AddVisualPoint(tileAbove,Color("#ffcd75"))
# 添加【左墙壁点】
func AddLeftWallPoint(tile:Vector2i):
	if TileAboveExist(tile):
		return
	
	if !TileEmpty(tile + Vector2i(-1,-1)):
		var tileAbove = Vector2i(0,-1) + tile
		var existingPointId:int = TileAlreadyExistInGraph(tileAbove)
		
		if existingPointId == -1: # 如果这个点没有添加，就添加为【左边缘点】
			var pointId:int = _astarGraph.get_available_point_id()
			var pointInfo = PointInfo.createPointInfo(pointId,Vector2i(map_to_local(tileAbove)))
			pointInfo.isLeftWall = true
			_pointInfoList.append(pointInfo)
			_astarGraph.add_point(pointId,Vector2i(map_to_local(tileAbove)))
			AddVisualPoint(tileAbove,Color(0,0,0,1))
		else:
			FilterListByID(existingPointId).isLeftWall = true
			AddVisualPoint(tileAbove,Color(0,0,0,1),0.45)
# 添加【右墙壁点】
func AddRightWallPoint(tile:Vector2i):
	if TileAboveExist(tile):
		return
	
	if !TileEmpty(tile + Vector2i(1,-1)):
		var tileAbove = Vector2i(0,-1) + tile
		var existingPointId:int = TileAlreadyExistInGraph(tileAbove)
		
		if existingPointId == -1: # 如果这个点没有添加，就添加为【左边缘点】
			var pointId:int = _astarGraph.get_available_point_id()
			var pointInfo = PointInfo.createPointInfo(pointId,Vector2i(map_to_local(tileAbove)))
			pointInfo.isRightWall = true
			_pointInfoList.append(pointInfo)
			_astarGraph.add_point(pointId,Vector2i(map_to_local(tileAbove)))
			AddVisualPoint(tileAbove,Color(0,0,0,1))
		else:
			FilterListByID(existingPointId).isRightWall = true
			AddVisualPoint(tileAbove,Color("556c86"),0.65)
#endregion 

# 如果瓷砖上面为空，返回false，否则返回true
func TileAboveExist(tile:Vector2i)->bool:
	if TileEmpty(tile + Vector2i(0,-1)):
		return false
	return true

# 如果该点位置为空，返回true
func TileEmpty(tile:Vector2i,layer:int = COLLISION_LAYER)->bool:
	if get_cell_source_id(layer,tile) == CELL_IS_EMPTY:
		return true
	return false

# 根据id找到数组中的PointInfo 【注意，这里默认能够找到且只找到一个！】
func FilterListByID(point_id:int)->PointInfo:
	for point_info in _pointInfoList:
		if point_info.PointID == point_id:
			return point_info
	return null
