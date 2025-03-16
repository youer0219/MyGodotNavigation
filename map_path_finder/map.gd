extends Node2D

@onready var path_finder: PathFinder = $PathFinder

@onready var map_layer: TileMapLayer = $MapLayer

@onready var path_show: PathShow = $PathShow

func _ready() -> void:
	await get_tree().create_timer(5.5).timeout
	path_show.queue_free()

func _on_timer_timeout() -> void:
	var path := path_finder.get_id_path(Vector2i(12,19),map_layer.local_to_map(get_local_mouse_position()))
	if is_instance_valid(path_show):
		path_show.show_path(path)
