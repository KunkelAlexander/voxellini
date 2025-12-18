extends Node3D

const DEBUG := false

@export var camera_path: NodePath
@export var terrain_path: NodePath

var selection_marker: MeshInstance3D
var camera: Camera3D
var terrain

var brush_radius := 2.0
const MIN_BRUSH_RADIUS := 1.0
const MAX_BRUSH_RADIUS := 4.0
const BRUSH_RADIUS_STEP := 0.1
const BRUSH_STRENGTH := 10
var last_hit_position: Vector3
var last_hit_normal: Vector3


func _ready():
	camera = get_node(camera_path)
	terrain = get_node(terrain_path)

	selection_marker = MeshInstance3D.new()
	selection_marker.mesh = SphereMesh.new()

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.4, 1.0, 0.25)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	selection_marker.material_override = mat
	selection_marker.visible = false
	add_child(selection_marker)


func get_camera_ray(max_dist := 100.0) -> Dictionary:
	var origin = camera.global_transform.origin
	var dir = camera.project_ray_normal(
		get_viewport().get_visible_rect().size * 0.5
	)
	var to = origin + dir * max_dist

	var query = PhysicsRayQueryParameters3D.create(origin, to)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	#query.exclude = [selection_marker.get_instance_rid()]

	return get_world_3d().direct_space_state.intersect_ray(query)


func _process(_dt):
	var hit = get_camera_ray()

	if hit.is_empty():
		selection_marker.visible = false
		return

	# Store surface info
	last_hit_position = hit.position
	last_hit_normal = hit.normal

	# Position brush slightly above surface
	selection_marker.visible = true
	selection_marker.global_position = (
		last_hit_position + last_hit_normal * 0.05
	)
	selection_marker.scale = Vector3.ONE * brush_radius * 1.0

	# Sculpting
	if Input.is_action_pressed("add_density"):
		if DEBUG:
			print("[Interactor] Add density at", last_hit_position)
		terrain.add_density_world(
			last_hit_position,
			-BRUSH_STRENGTH,
			brush_radius
		)

	if Input.is_action_pressed("remove_density"):
		if DEBUG:
			print("[Interactor] Remove density at", last_hit_position)
		terrain.add_density_world(
			last_hit_position,
			+BRUSH_STRENGTH,
			brush_radius
		)


func _unhandled_input(event):
	if event.is_action_pressed("brush_radius_up"):
		brush_radius = clamp(
			brush_radius + BRUSH_RADIUS_STEP,
			MIN_BRUSH_RADIUS,
			MAX_BRUSH_RADIUS
		)
		if DEBUG:
			print("[Interactor] Brush radius:", brush_radius)

	elif event.is_action_pressed("brush_radius_down"):
		brush_radius = clamp(
			brush_radius - BRUSH_RADIUS_STEP,
			MIN_BRUSH_RADIUS,
			MAX_BRUSH_RADIUS
		)
		if DEBUG:
			print("[Interactor] Brush radius:", brush_radius)
