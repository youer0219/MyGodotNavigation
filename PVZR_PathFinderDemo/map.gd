extends Node2D

@onready var path_finder: PathFinder = $PathFinder
@onready var map_layer: TileMapLayer = $MapLayer
@onready var path_show: PathShow = $PathShow


func _on_timer_timeout() -> void:
	var path := path_finder.get_id_path(Vector2i(10,20),map_layer.local_to_map(get_local_mouse_position()))
	if is_instance_valid(path_show):
		var new_path := path_finder.filter_path(path)
		path_show.show_path(new_path)
