@tool
class_name RoadGenerator_Terrain3D
extends Node3D

## === CONFIGURAÇÕES ===
@export_category("Caminho e Terreno")
@export var terrain: Node3D

var _path_internal: Path3D
@export var path: Path3D:
	get: return _path_internal
	set(value): _set_path(value)

@export_category("Propriedades da Estrada")
@export_range(0.1, 50.0, 0.1) var road_width: float = 5.0:
	set(value):
		road_width = value
		_generate_on_property_change()
@export_range(0.01, 2.0, 0.01) var base_resolution: float = 0.5:
	set(value):
		base_resolution = value
		_generate_on_property_change()
@export_range(0.1, 100.0, 0.1) var uv_scale: float = 10.0:
	set(value):
		uv_scale = value
		_generate_on_property_change()
@export var road_material: Material:
	set(value):
		road_material = value
		_generate_on_property_change()
@export var generate_collision: bool = true:
	set(value):
		generate_collision = value
		_generate_on_property_change()
@export var deform_terrain: bool = false:
	set(value):
		deform_terrain = value
		_generate_on_property_change()
@export var terrain_deformer: Node = null:
	set(value):
		terrain_deformer = value
		_generate_on_property_change()

@export_category("Sistema de LOD")
@export var use_auto_lod: bool = true:
	set(value):
		use_auto_lod = value
		_update_lod_debug_visibility()
@export_range(1, 1000, 1) var lod_distance_threshold: float = 50.0
@export var lod_levels: Array[float] = [1.0, 0.5, 0.2]:
	set(value):
		if value.size() >= 3:
			lod_levels = value
			_update_lod_settings()

@export_category("Integração com Plugins")
@export var lane_manager: Node = null:
	set(value):
		lane_manager = value
		_generate_on_property_change()
@export var traffic_system: Node = null:
	set(value):
		traffic_system = value
		_generate_on_property_change()

## === INTERNOS ===
var _mesh_instance: MeshInstance3D
var _array_mesh: ArrayMesh
var _collision_shape: CollisionShape3D
var _directions: PackedVector3Array = PackedVector3Array()
var _terrain_has_height: bool = false
var _terrain_has_normal: bool = false
var _current_resolution: float = 0.5
var _lod_debug: Label3D
var _is_generating: bool = false

func _enter_tree():
	if Engine.is_editor_hint():
		_setup_editor()
		generate_road()

func _exit_tree():
	# Limpeza segura para evitar erros no editor
	if _path_internal and _path_internal.curve and _path_internal.curve.changed.is_connected(_on_curve_changed):
		_path_internal.curve.changed.disconnect(_on_curve_changed)

func _ready():
	if !Engine.is_editor_hint():
		_setup_runtime()
		generate_road()
	else:
		# Configuração visual para o editor
		_lod_debug = Label3D.new()
		_lod_debug.text = "LOD: 0"
		_lod_debug.font_size = 24
		_lod_debug.pixel_size = 0.005
		_lod_debug.visible = use_auto_lod and Engine.is_editor_hint()
		add_child(_lod_debug)

func _process(delta):
	if !use_auto_lod or !_mesh_instance or Engine.is_editor_hint():
		return

	var camera = get_viewport().get_camera_3d()
	if camera:
		var distance = global_transform.origin.distance_to(camera.global_transform.origin)
		_update_lod_based_on_distance(distance)

func _set_path(value):
	# Desconectar do path anterior
	if _path_internal and _path_internal.curve and _path_internal.curve.changed.is_connected(_on_curve_changed):
		_path_internal.curve.changed.disconnect(_on_curve_changed)

	_path_internal = value

	# Conectar ao novo path
	if _path_internal and _path_internal.curve:
		_path_internal.curve.changed.connect(_on_curve_changed)

	if Engine.is_editor_hint() or !Engine.is_editor_hint() and is_inside_tree():
		generate_road()

func _on_curve_changed():
	if Engine.is_editor_hint() and is_inside_tree() and !_is_generating:
		call_deferred("generate_road")

func _setup_editor():
	_mesh_instance = _find_or_create_mesh_instance()
	_cache_terrain_methods()
	_update_lod_settings()
	
	# Garantir que estamos conectados ao sinal
	if _path_internal and _path_internal.curve and !_path_internal.curve.changed.is_connected(_on_curve_changed):
		_path_internal.curve.changed.connect(_on_curve_changed)

func _setup_runtime():
	if !_path_internal or !terrain:
		push_error("Path ou Terrain não definidos!")
		return

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "RoadMesh"
	add_child(_mesh_instance)
	_cache_terrain_methods()
	_update_lod_settings()

func _find_or_create_mesh_instance() -> MeshInstance3D:
	for child in get_children():
		if child is MeshInstance3D and child.name == "RoadMesh":
			return child
	var mi = MeshInstance3D.new()
	mi.name = "RoadMesh"
	add_child(mi)
	return mi

func _cache_terrain_methods():
	if is_instance_valid(terrain):
		_terrain_has_height = terrain.has_method("get_height_at")
		_terrain_has_normal = terrain.has_method("get_normal_at")

func _update_lod_settings():
	if lod_levels.size() < 3:
		lod_levels = [1.0, 0.5, 0.2]
	_current_resolution = lod_levels[0] if Engine.is_editor_hint() else lod_levels[1]

func _update_lod_based_on_distance(distance: float):
	var lod = 0
	if distance < lod_distance_threshold * 0.5:
		lod = 0
	elif distance < lod_distance_threshold:
		lod = 1
	else:
		lod = 2
	var res = lod_levels[lod]
	if res != _current_resolution:
		_current_resolution = res
		generate_road()

	if is_instance_valid(_lod_debug):
		_lod_debug.text = "LOD: %d\nDist: %.1f" % [lod, distance]
		_lod_debug.position = Vector3(0, road_width * 0.6, 0)

func _update_lod_debug_visibility():
	if is_instance_valid(_lod_debug):
		_lod_debug.visible = use_auto_lod and Engine.is_editor_hint()

func _generate_on_property_change():
	if Engine.is_editor_hint() and is_inside_tree() and !_is_generating:
		call_deferred("generate_road")

func update_road():
	generate_road()

# --- GERAÇÃO ---
func generate_road():
	if _is_generating or !is_inside_tree():
		return
		
	_is_generating = true
	
	if !is_instance_valid(_path_internal) or !is_instance_valid(terrain):
		_is_generating = false
		return

	var points = _sample_curve_points()
	if points.size() < 2:
		push_warning("Poucos pontos para gerar estrada.")
		_is_generating = false
		return

	_precalculate_directions(points)
	_create_road_mesh(points)

	if generate_collision:
		_update_collision()

	if deform_terrain and is_instance_valid(terrain_deformer) and terrain_deformer.has_method("deformar"):
		terrain_deformer.call_deferred("deformar", points, road_width)

	if is_instance_valid(lane_manager) and lane_manager.has_method("generate_lane_dummies"):
		lane_manager.call_deferred("generate_lane_dummies")

	if is_instance_valid(traffic_system) and traffic_system.has_method("initialize_from_road"):
		traffic_system.call_deferred("initialize_from_road", self)
	
	_is_generating = false

# --- AMOSTRAGEM ---
func _sample_curve_points() -> PackedVector3Array:
	var points = PackedVector3Array()
	if !is_instance_valid(_path_internal) or !_path_internal.curve:
		return points

	var curve = _path_internal.curve
	var length = curve.get_baked_length()
	var res = _current_resolution
	var count = max(2, int(length * res) + 1)

	for i in count:
		var t = min(i * res, length)
		var pos = curve.sample_baked(t)

		if _terrain_has_height and is_instance_valid(terrain):
			var in_bounds = false
			if terrain.has_method("is_in_bounds") and terrain.call("is_in_bounds", pos.x, pos.z):
				pos.y = terrain.call("get_height_at", pos.x, pos.z)
			elif terrain.has_method("get_height_at"):
				pos.y = terrain.call("get_height_at", pos.x, pos.z)
			else:
				pos.y = 0.0

		points.append(pos)

	return points

# --- DIREÇÕES ---
func _precalculate_directions(points: PackedVector3Array):
	_directions = PackedVector3Array()
	var count = points.size()
	if count < 2: 
		return

	for i in count:
		if i == 0:
			_directions.append((points[1] - points[0]).normalized())
		elif i == count - 1:
			_directions.append((points[i] - points[i-1]).normalized())
		else:
			var prev_dir = (points[i] - points[i-1]).normalized()
			var next_dir = (points[i+1] - points[i]).normalized()
			_directions.append((prev_dir + next_dir).normalized())

# --- BINORMAL ---
func _get_binormal(dir: Vector3) -> Vector3:
	if dir.is_equal_approx(Vector3.UP) or dir.is_equal_approx(Vector3.DOWN):
		return Vector3.RIGHT.cross(Vector3.UP).normalized()
	return Vector3.UP.cross(dir).normalized()

# --- NORMAL ---
func _get_terrain_normal(pos: Vector3) -> Vector3:
	if _terrain_has_normal and is_instance_valid(terrain):
		if terrain.has_method("is_in_bounds") and terrain.call("is_in_bounds", pos.x, pos.z):
			return terrain.call("get_normal_at", pos.x, pos.z)
		elif terrain.has_method("get_normal_at"):
			return terrain.call("get_normal_at", pos.x, pos.z)
	return Vector3.UP

# --- MALHA ---
func _create_road_mesh(points: PackedVector3Array):
	if !is_instance_valid(_mesh_instance):
		return
		
	var verts = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	var count = points.size()

	verts.resize(count * 2)
	uvs.resize(count * 2)
	normals.resize(count * 2)

	for i in count:
		var binormal = _get_binormal(_directions[i])
		var left = points[i] + binormal * road_width * 0.5
		var right = points[i] - binormal * road_width * 0.5
		var idx = i * 2

		verts[idx] = left
		verts[idx + 1] = right

		var u = float(i) / (count - 1) if count > 1 else 0.0
		uvs[idx] = Vector2(u * uv_scale, 0)
		uvs[idx + 1] = Vector2(u * uv_scale, 1)

		var normal = _get_terrain_normal(points[i])
		normals[idx] = normal
		normals[idx + 1] = normal

	if count > 1:
		indices.resize((count - 1) * 6)
		for i in range(count - 1):
			var bi = i * 6
			var vi = i * 2
			indices[bi] = vi
			indices[bi+1] = vi+2
			indices[bi+2] = vi+1
			indices[bi+3] = vi+1
			indices[bi+4] = vi+2
			indices[bi+5] = vi+3

	if !_array_mesh:
		_array_mesh = ArrayMesh.new()
	else:
		_array_mesh.clear_surfaces()

	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_NORMAL] = normals
	if count > 1:
		arr[Mesh.ARRAY_INDEX] = indices

	_array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	if road_material:
		_array_mesh.surface_set_material(0, road_material)

	_mesh_instance.mesh = _array_mesh
	if Engine.is_editor_hint():
		_mesh_instance.queue_redraw()

# --- COLISÃO ---
func _update_collision():
	if is_instance_valid(_collision_shape):
		remove_child(_collision_shape)
		_collision_shape.queue_free()
		_collision_shape = null

	if generate_collision and is_instance_valid(_array_mesh) and _array_mesh.get_surface_count() > 0:
		_collision_shape = CollisionShape3D.new()
		_collision_shape.name = "RoadCollision"
		add_child(_collision_shape)

		var shape = ConcavePolygonShape3D.new()
		shape.set_faces(_array_mesh.get_faces())
		_collision_shape.shape = shape

# --- API PÚBLICA ---
func get_road_points() -> PackedVector3Array:
	return _sample_curve_points() if is_instance_valid(_path_internal) else PackedVector3Array()

func get_road_directions() -> PackedVector3Array:
	return _directions

func get_road_width() -> float:
	return road_width

# --- EDITOR ---
func _get_property_list():
	var properties = []
	properties.append({
		"name": "RoadGenerator_Terrain3D",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_CATEGORY,
		"hint_string": "Road Generator"
	})
	return properties