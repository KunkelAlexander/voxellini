extends Node3D
class_name VoxelChunk


enum RenderMode {
	MARCHING_CUBES,
	BLOCKS
}

@export var render_mode: RenderMode = RenderMode.MARCHING_CUBES


signal dirty_requested(chunk: VoxelChunk)

var mesh_instance: MeshInstance3D
var static_body: StaticBody3D
var collision_shape: CollisionShape3D
var chunk_coord: Vector3i        # chunk-space coordinate

const SIZE := 16

const SIZE_X           := SIZE
const SIZE_Y           := SIZE
const SIZE_Z           := SIZE

const ISO_LEVEL        := +0.0
const AIR              := +1.0  # or any positive value = outside
const SOLID            := -1.0
const DEBUG            := false
const DEBUG_MESH       := false
const BRUSH_RADIUS     := 2
const DEFAULT_MATERIAL := 0
const NO_MATERIAL      := -1

# We store materials on grid points and interpolate to vertex colours in the first step
# Alternatively one could colour the generated verticles which would be more precise
# This could be a layer on top (i.e. material with a paint on top)
var density_field      := {} # Dictionary<Vector3i, float>
var material_id_field  := {} # Dictionary<Vector3i, int>

var dirty := false

@export var mesher: VoxelMesher


func mark_dirty():
	if dirty:
		return
	dirty = true
	emit_signal("dirty_requested", self)
	
func get_density_field() -> Dictionary:
	return density_field

func get_material_field() -> Dictionary:
	return material_id_field

func set_density_field(d: Dictionary):
	density_field = d

func set_material_field(m: Dictionary):
	material_id_field = m

# Getters and setters for material and density fields
# Index the density and material fields using integers only
func get_density(p: Vector3i) -> float:
	return density_field.get(p, AIR)

func get_material(p: Vector3i) -> int:
	return material_id_field.get(p, NO_MATERIAL)
	
func set_density(p: Vector3i, value):
	if value > 0.0:
		density_field.erase(p)
	else:
		density_field[p] = value

func set_material(p: Vector3i, value):
	if density_field.has(p):
		material_id_field[p] = value
	else:
		material_id_field.erase(p)
		
func set_density_halo(p: Vector3i, value):
	# local_p is allowed to be outside [0..SIZE-1]
	set_density(p, value)

func set_material_halo(p: Vector3i, value):
	# local_p is allowed to be outside [0..SIZE-1]
	set_material(p, value)

func init_density():
	if true:
		return

func owns_sample(p: Vector3i) -> bool:
	return (p.x >= 0 && p.x < SIZE_X) && (p.y >= 0 && p.y < SIZE_Y) && (p.z >= 0 && p.z < SIZE_Z)



func _ready():
	
	if mesher == null:
		mesher = MarchingCubesMesher.new()
	# Mesh
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	add_child(mesh_instance)

	# Physics
	static_body = StaticBody3D.new()
	static_body.name = "StaticBody3D"
	add_child(static_body)

	collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	static_body.add_child(collision_shape)
	
	init_density()
	mark_dirty()
	
func _on_palette_changed():
	mark_dirty()

func generate_mesh():
	var vertices: PackedVector3Array = []
	var normals:  PackedVector3Array = []
	var colors:   PackedColorArray   = []

	if DEBUG_MESH:
		print("Number of density points: ", density_field.size())
		print("Number of material points: ", material_id_field.size())


	mesher.generate(self, vertices, normals, colors)


	if DEBUG_MESH:
		print("total vertices:", vertices.size())
		for i in range(vertices.size()):
			print("v[", i, "] = ", vertices[i])

	build_mesh(vertices, normals, colors)


func build_mesh(vertices, normals, colors): 
		
	var mesh := ArrayMesh.new()
	
	# Skip mesh generation if there are no vertices but make sure to set empty mesh
	if vertices.size():
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_COLOR]  = colors
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = mesh

	# Update collision
	if mesh.get_surface_count() == 0:
		collision_shape.shape = null
		return

	collision_shape.shape = mesh.create_trimesh_shape()

	# Enable vertex colours
	if mesh_instance.material_override == null:
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mesh_instance.material_override = mat
