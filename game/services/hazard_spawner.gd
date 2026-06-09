class_name HazardSpawner
extends RefCounted

var _items_root: Node2D
var _spawn_rect: Rect2

var _dragon_scene: PackedScene = preload(GameConfig.SCENE_DRAGON)
var _bat_scene: PackedScene = preload(GameConfig.SCENE_BAT)
var _mole_scene: PackedScene = preload(GameConfig.SCENE_MOLE)


func setup(items_root: Node2D, spawn_rect: Rect2) -> void:
	_items_root = items_root
	_spawn_rect = spawn_rect


func spawn_for_floor(session: RunSession) -> void:
	var hazard_ids := LevelData.roll_floor_hazards(
		session.floor_depth,
		session.is_vault_floor,
		session.rng,
	)
	var used_positions: Array[Vector2] = []

	for hazard_id in hazard_ids:
		var spawn_data := LevelData.get_hazard_spawn(
			hazard_id,
			session.current_layout,
			_spawn_rect,
			session.rng,
			used_positions,
		)
		match hazard_id:
			"dragon":
				var dragon: DragonGuardian = _dragon_scene.instantiate()
				dragon.setup(spawn_data["patrol_left"], spawn_data["patrol_right"], spawn_data["y"])
				_items_root.add_child(dragon)
			"bat":
				var bat: CaveBat = _bat_scene.instantiate()
				bat.setup(spawn_data["patrol_left"], spawn_data["patrol_right"], spawn_data["y"])
				_items_root.add_child(bat)
			"mole":
				var mole: TunnelMole = _mole_scene.instantiate()
				mole.setup(spawn_data["x"], spawn_data["y"])
				used_positions.append(Vector2(spawn_data["x"], spawn_data["y"]))
				_items_root.add_child(mole)
