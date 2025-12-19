extends Node3D

const DEBUG := false

@export var camera_path: NodePath
@export var terrain_path: NodePath

var selection_marker: MeshInstance3D
var camera: Camera3D
var terrain

# Select sculpting or painting
enum Tool {
	SCULPT,
	PAINT,
}

var current_tool := Tool.SCULPT
var current_material_id := 0

var brush_radius := 2.0
const MIN_BRUSH_RADIUS := 1.0
const MAX_BRUSH_RADIUS := 4.0
const BRUSH_RADIUS_STEP := 0.1
const BRUSH_STRENGTH := 10
var last_hit_position: Vector3
var last_hit_normal: Vector3

# Implement undo/redo using command pattern
var undo_stack := []
var redo_stack := []

var active_command: VoxelBrushCommand = null


func _ready():
	camera = get_node(camera_path)
	terrain = get_node(terrain_path)

	selection_marker = MeshInstance3D.new()
	selection_marker.mesh = SphereMesh.new()

	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	selection_marker.material_override = mat
	selection_marker.visible = false
	update_brush_visual()
	add_child(selection_marker)
	
	
	Game.world_loaded.connect(_on_world_loaded)



func _process(_dt):
	
	if Game.mode != Game.Mode.GAMEPLAY:
		return
		
	var hit = get_camera_ray()

	if hit.is_empty():
		selection_marker.visible = false
		return

	# Store surface info
	last_hit_position = hit.position
	last_hit_normal   = hit.normal

	# Position brush slightly above surface
	selection_marker.visible = true
	selection_marker.global_position = (
		last_hit_position + last_hit_normal * 0.05
	)
	selection_marker.scale = Vector3.ONE * brush_radius * 1.0

	match current_tool:
		Tool.SCULPT:
			_process_sculpting()
		Tool.PAINT:
			_process_painting()
			
func _process_sculpting():
	if active_command == null:
		return

	# Sculpting
	if Input.is_action_pressed("add_density"):
		if DEBUG:
			print("[Interactor] Add density at", last_hit_position)
		terrain.add_density_world(
			last_hit_position,
			-BRUSH_STRENGTH,
			brush_radius,
			current_material_id,
			active_command
		)

	if Input.is_action_pressed("remove_density"):
		if DEBUG:
			print("[Interactor] Remove density at", last_hit_position)
		terrain.add_density_world(
			last_hit_position,
			+BRUSH_STRENGTH,
			brush_radius,
			terrain.DEFAULT_MATERIAL,
			active_command
		)

func _process_painting():
	if Input.is_action_pressed("add_density"):
		if DEBUG:
			print("[Interactor] Paint material", current_material_id,
				  "at", last_hit_position)
		terrain.add_density_world(
			last_hit_position,
			0,
			brush_radius, 
			current_material_id,
			active_command
		)

func _unhandled_input(event):
	
	if Game.mode != Game.Mode.GAMEPLAY:
		return
		
	# Start sculpt stroke
	if event.is_action_pressed("add_density") or event.is_action_pressed("remove_density"):
		if active_command == null:
			active_command = VoxelBrushCommand.new()
			if DEBUG:
				print("[Command] Begin brush stroke")

	# End sculpt stroke
	if event.is_action_released("add_density") or event.is_action_released("remove_density"):
		if active_command != null:
			undo_stack.append(active_command)
			redo_stack.clear()
			if DEBUG:
				print("[Command] End brush stroke, voxels:",
					  active_command.before.size())
			active_command = null
			
	if event.is_action_pressed("tool_sculpt"):
		current_tool = Tool.SCULPT
		update_brush_visual()
		if DEBUG:
			print("[Tool] Sculpt")

	elif event.is_action_pressed("tool_paint"):
		current_tool = Tool.PAINT
		update_brush_visual()
		if DEBUG:
			print("[Tool] Paint")
			
	if event.is_action_pressed("next_material"):
		current_material_id += 1

		var count := material_palette.size()
		if count > 0:
			current_material_id = current_material_id % count
		else:
			current_material_id = 0

		update_brush_visual()

		if DEBUG:
			print("[Material] Current material ID:", current_material_id)
			
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
			
	if event.is_action_pressed("undo") and undo_stack.size() > 0:
		var cmd = undo_stack.pop_back()
		cmd.undo(terrain)
		redo_stack.append(cmd)

	elif event.is_action_pressed("redo") and redo_stack.size() > 0:
		var cmd = redo_stack.pop_back()
		cmd.execute(terrain)
		undo_stack.append(cmd)

# Let's make this a texture lookup later
var material_palette : Array[Color] = INFERNO_COLORS
const INFERNO_COLORS : Array[Color] =  [
	Color(0.000, 0.000, 0.016),  # very dark
	Color(0.259, 0.039, 0.408),
	Color(0.576, 0.149, 0.404),
	Color(0.867, 0.318, 0.227),
	Color(0.988, 0.647, 0.039),
	Color(0.988, 1.000, 0.643),  # bright
]



func update_brush_visual():
	var mat := selection_marker.material_override as StandardMaterial3D
	var c := material_palette[current_material_id]
	mat.albedo_color = Color(c.r, c.g, c.b, 0.25)


func get_camera_ray(max_dist := 100.0) -> Dictionary:
	var origin = camera.global_transform.origin
	var dir = camera.project_ray_normal(
		get_viewport().get_visible_rect().size * 0.5
	)
	var to = origin + dir * max_dist

	var query = PhysicsRayQueryParameters3D.create(origin, to)
	query.collide_with_bodies = true
	query.collide_with_areas = false

	return get_world_3d().direct_space_state.intersect_ray(query)

func _on_world_loaded(world):
	undo_stack.clear()
	redo_stack.clear()
