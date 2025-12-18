@tool
extends Node3D

@export var size_x := 8
@export var size_y := 8
@export var size_z := 8
@export var spacing := 1.0

var mesh := ImmediateMesh.new()

func _ready():
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	add_child(mi)
	draw_grid()

func draw_grid():
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	for x in range(size_x + 1):
		for y in range(size_y + 1):
			mesh.surface_add_vertex(Vector3(x, y, 0) * spacing)
			mesh.surface_add_vertex(Vector3(x, y, size_z) * spacing)

	for x in range(size_x + 1):
		for z in range(size_z + 1):
			mesh.surface_add_vertex(Vector3(x, 0, z) * spacing)
			mesh.surface_add_vertex(Vector3(x, size_y, z) * spacing)

	for y in range(size_y + 1):
		for z in range(size_z + 1):
			mesh.surface_add_vertex(Vector3(0, y, z) * spacing)
			mesh.surface_add_vertex(Vector3(size_x, y, z) * spacing)

	mesh.surface_end()
