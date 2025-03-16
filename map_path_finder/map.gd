extends Node2D

@onready var path_finder: PathFinder = $PathFinder

@onready var map_layer: TileMapLayer = $MapLayer

@onready var path_show: PathShow = $PathShow


func _on_timer_timeout() -> void:
	var path := path_finder.get_id_path(Vector2i(2,3),map_layer.local_to_map(get_local_mouse_position()))
	path_show.show_path(path)
