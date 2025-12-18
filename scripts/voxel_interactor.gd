extends Node3D

const DEBUG := true

@export var camera_path: NodePath
@export var terrain_path: NodePath

var selection_marker: MeshInstance3D
var camera: Camera3D
var terrain


func _ready():
	camera = get_node(camera_path)
	terrain = get_node(terrain_path)

	if DEBUG:
		print("[VoxelInteractor] Ready")
		print("  Camera:", camera)
		print("  Terrain:", terrain)

	selection_marker = MeshInstance3D.new()
	selection_marker.mesh = SphereMesh.new()
	selection_marker.scale = Vector3.ONE * 0.2

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.4, 1.0, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	selection_marker.material_override = mat
	selection_marker.visible = false
	add_child(selection_marker)

	if DEBUG:
		print("[VoxelInteractor] Selection marker created")


func get_camera_ray(max_dist := 100.0) -> Dictionary:
	var origin = camera.global_transform.origin
	var dir = camera.project_ray_normal(
		get_viewport().get_visible_rect().size * 0.5
	)
	var to = origin + dir * max_dist

	if DEBUG:
		print("[Raycast]")
		print("  Origin:", origin)
		print("  Direction:", dir)
		print("  To:", to)

	var query = PhysicsRayQueryParameters3D.create(origin, to)
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var hit = get_world_3d().direct_space_state.intersect_ray(query)

	if DEBUG:
		if hit.is_empty():
			print("  → No hit")
		else:
			print("  → Hit at:", hit.position)
			print("    Collider:", hit.collider)

	return hit


func world_to_grid(p: Vector3) -> Vector3i:
	var g = Vector3i(floor(p.x), floor(p.y), floor(p.z))
	if DEBUG:
		print("  world_to_grid:", p, "→", g)
	return g


func nearest_grid_point(hit_pos: Vector3) -> Vector3i:
	if DEBUG:
		print("[Grid Resolve]")
		print("  Hit position:", hit_pos)

	var base = world_to_grid(hit_pos)
	var local = hit_pos - Vector3(base)

	if DEBUG:
		print("  Base cell:", base)
		print("  Local pos:", local)

	var p = Vector3i(
		base.x + int(local.x > 0.5),
		base.y + int(local.y > 0.5),
		base.z + int(local.z > 0.5)
	)

	if DEBUG:
		print("  Nearest grid point:", p)

	return p


func is_valid_selection(p: Vector3i) -> bool:
	if DEBUG:
		print("  Validate selection:", p)
	# return terrain.has_density(p) or terrain.is_ground(p)
	return true


func _process(_dt):
	var hit = get_camera_ray()

	if hit.is_empty():
		if selection_marker.visible:
			if DEBUG:
				print("[Selection] Cleared (no hit)")
		selection_marker.visible = false
		return

	var p = nearest_grid_point(hit.position)

	if not is_valid_selection(p):
		if DEBUG:
			print("[Selection] Invalid:", p)
		selection_marker.visible = false
		return

	if DEBUG:
		print("[Selection] Valid:", p)

	selection_marker.visible = true
	selection_marker.global_position = Vector3(p)
