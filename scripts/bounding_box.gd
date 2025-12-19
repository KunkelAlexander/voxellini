extends Node3D

@export var size := Vector3(16, 16, 16)
@export var color := Color(0.2, 0.6, 1.0, 0.08)

func _ready():
	var box := MeshInstance3D.new()
	var mesh := BoxMesh.new()

	# BoxMesh is centered → scale to full size
	mesh.size = size

	box.mesh = mesh
	box.position = size * 0.5  # move to voxel space

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	box.material_override = mat
	add_child(box)
