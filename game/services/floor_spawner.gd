class_name FloorSpawner
extends RefCounted

var _items_root: Node2D
var _spawn_rect: Rect2

var _item_scene: PackedScene = preload(GameConfig.SCENE_ITEM)
var _chest_scene: PackedScene = preload(GameConfig.SCENE_CHEST)


func setup(items_root: Node2D, spawn_rect: Rect2) -> void:
	_items_root = items_root
	_spawn_rect = spawn_rect


func clear() -> void:
	for child in _items_root.get_children():
		child.queue_free()


func spawn_layout(layout: Array[Dictionary]) -> void:
	for entry in layout:
		var pos := _layout_to_world(entry)
		if entry.get("id") == "chest":
			var chest: TreasureChest = _chest_scene.instantiate()
			chest.global_position = pos
			_items_root.add_child(chest)
			continue

		var item: MineItem = _item_scene.instantiate()
		item.setup(entry["id"])
		item.global_position = pos
		_items_root.add_child(item)


func only_chests_remain() -> bool:
	for child in _items_root.get_children():
		if child is MineItem:
			return false
	return _items_root.get_child_count() == 0


func collect_mine_items_in_radius(origin: Vector2, radius: float, exclude: MineItem = null) -> Array[MineItem]:
	var victims: Array[MineItem] = []
	for child in _items_root.get_children():
		if child is MineItem and child != exclude and child.global_position.distance_to(origin) <= radius:
			victims.append(child)
	return victims


func _layout_to_world(entry: Dictionary) -> Vector2:
	return Vector2(
		_spawn_rect.position.x + _spawn_rect.size.x * entry["x"],
		_spawn_rect.position.y + _spawn_rect.size.y * entry["y"],
	)
