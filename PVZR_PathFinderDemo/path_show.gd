extends Node2D
class_name PathShow

@export var map:TileMapLayer

func show_path(cells:Array[Vector2i]):
	var global_cells = PathShowTool.change_tilemaplayer_cells_to_global_cells(cells,map)
	PathShowTool.draw_path(self,global_cells,Color.BLUE_VIOLET,10)
