extends Node2D

const PATH_SHOW_EXECUTOR = preload("res://path_show_tool/path_show_executor.tscn")

## 节点请求绘制路径，传递全局坐标的路径数组和自身
## 根据自身ID判断是否存在绘制节点，如果存在，更新该节点的绘制；如果不存在，选择一个空闲的执行者进行绘制
## 如果是第一次，还会链接其离开树的信号，在此时删除路径。

## 不限制高峰时绘制执行者数量。但当绘制结束时，如果执行者节点数量超过 MAX_COMOMN_PATH_SHOW_EXECUTOR_NUM,就会删除执行者节点
## 请根据自己的绘制需求合理调节这个值
const MAX_COMOMN_PATH_SHOW_EXECUTOR_NUM := 10

func draw_path(node:Node,paths:Array[Vector2],path_color:Color = Color.ALICE_BLUE ,path_circle_radius:float = 1.0):
	## 尝试在node.free()后传入node，编辑器直接报错。因此这里感觉不会被触发。
	#if not is_instance_valid(node):
		#push_error(node,"节点已经被销毁！")
	
	if not node.is_inside_tree():
		push_error(node,"节点尚未进入树中！")
		return
	
	var node_id := node.get_instance_id()
	
	var path_show_executor := _find_path_show_executor_by_id(node_id)
	if path_show_executor == null:
		path_show_executor = _find_spare_path_show_executor()
		path_show_executor.path_requester_id = EncodedObjectAsID.new()
		path_show_executor.path_requester_id.object_id = node_id
		node.tree_exiting.connect(draw_path_clear.bind(node))
	
	path_show_executor.path_color = path_color
	path_show_executor.path_circle_radius  = path_circle_radius
	path_show_executor.paths = paths
	path_show_executor.update_path()

## 清除指定节点请求的绘制
func draw_path_clear(node:Node):
	var node_id := node.get_instance_id()
	var path_show_executor := _find_path_show_executor_by_id(node_id)
	if is_instance_valid(path_show_executor):
		var path_show_executors_num = get_child_count()
		if path_show_executors_num <= MAX_COMOMN_PATH_SHOW_EXECUTOR_NUM:
			path_show_executor.path_requester_id = null
			path_show_executor.paths = []
			path_show_executor.update_path()
		else:
			if node.tree_exiting.is_connected(draw_path_clear):
				node.tree_exiting.disconnect(draw_path_clear)
			path_show_executor.queue_free()
	else:
		push_warning(node,"绘制节点被强制删除或对象没有请求过绘制却要求清除绘制!")


## 寻找这个ID对应的执行者。不存在即为第一次请求绘制。存在即返回对应的执行者。
func _find_path_show_executor_by_id(id:int)->PathShowExecutor:
	
	for path_show_executor in _get_path_show_executors():
		if path_show_executor.path_requester_id == null:
			continue
		if path_show_executor.path_requester_id.object_id == id:
			return path_show_executor
	
	return null

## 找到一个空闲的执行者或创建一个新的执行者
func _find_spare_path_show_executor()->PathShowExecutor:
	
	for path_show_executor in _get_path_show_executors():
		if path_show_executor.path_requester_id == null:
			return path_show_executor
	
	var new_path_show_executor = PATH_SHOW_EXECUTOR.instantiate() as PathShowExecutor
	add_child(new_path_show_executor)
	return new_path_show_executor

func _get_path_show_executors()->Array[PathShowExecutor]:
	return Array(get_children(),TYPE_OBJECT,"Node2D",PathShowExecutor)

#region 工具方法

func change_tilemaplayer_cells_to_global_cells(cells:Array[Vector2i],map:TileMapLayer)->Array[Vector2]:
	var global_cells:Array[Vector2] = []
	for cell in cells:
		var local_cell := map.map_to_local(cell)
		global_cells.append(map.to_global(local_cell))
	return global_cells

func change_tilemap_cells_to_global_cells(cells:Array[Vector2i],map:TileMap)->Array[Vector2]:
	var global_cells:Array[Vector2] = []
	for cell in cells:
		var local_cell := map.map_to_local(cell)
		global_cells.append(map.to_global(local_cell))
	return global_cells

#endregion
