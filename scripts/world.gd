extends Node3D

const DEBUG := false 
const DEFAULT_MATERIAL := 0
var chunks := {}  # Dictionary<Vector3i, VoxelChunk>
var dirty_chunks: Array[VoxelChunk] = []

func _ready():
	add_to_group("world")

# Return 3D index of chunk where p is located
func world_to_chunk(p: Vector3i) -> Vector3i:
	return Vector3i(
		floor(float(p.x) / float(VoxelChunk.SIZE)),
		floor(float(p.y) / float(VoxelChunk.SIZE)),
		floor(float(p.z) / float(VoxelChunk.SIZE))
	)
	
# Return local chunk coordinates from 0 to VoxelChunk.SIZE - 1
func world_to_local(p: Vector3i) -> Vector3i:
	return Vector3i(
		posmod(p.x, VoxelChunk.SIZE),
		posmod(p.y, VoxelChunk.SIZE),
		posmod(p.z, VoxelChunk.SIZE)
	)

func get_or_create_chunk(chunk_coord: Vector3i) -> VoxelChunk:
	if chunks.has(chunk_coord):
		return chunks[chunk_coord]
	if DEBUG:
		print("Create new chunk c = ", chunk_coord)
	var chunk := VoxelChunk.new()
	chunk.chunk_coord = chunk_coord
	chunk.position    = Vector3(chunk_coord) * VoxelChunk.SIZE
	chunk.dirty_requested.connect(_on_chunk_dirty_requested)
	add_child(chunk)
	
	

	chunks[chunk_coord] = chunk
	return chunk

func _on_chunk_dirty_requested(chunk: VoxelChunk):
	if not dirty_chunks.has(chunk):
		dirty_chunks.append(chunk)


func mark_chunk_dirty(chunk_coord: Vector3i):
	if chunks.has(chunk_coord):
		chunks[chunk_coord].mark_dirty()

# Check 26 direct neighbours of p to detect whether it borders
func get_boundary_neighbor_offsets(p: Vector3i) -> Array[Vector3i]:
	var offsets: Array[Vector3i] = []

	var base_chunk := world_to_chunk(p)
	var seen := {}

	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				if dx == 0 and dy == 0 and dz == 0:
					continue

				var neighbor_world := p + Vector3i(dx, dy, dz)
				var neighbor_chunk := world_to_chunk(neighbor_world)

				if neighbor_chunk != base_chunk:
					var offset := neighbor_chunk - base_chunk
					if not seen.has(offset):
						seen[offset] = true
						offsets.append(offset)

	return offsets
	
func set_density(p: Vector3i, d: float):
	var c = world_to_chunk(p)
	var l = world_to_local(p)

	var chunk = get_or_create_chunk(c)
	chunk.set_density(l, d)
	mark_chunk_dirty(c)
	
	# Propagate dirtiness to neighbors if on boundary
	var neighbor_offsets := get_boundary_neighbor_offsets(p)
	
	for offset in neighbor_offsets:
		var neighbor = get_or_create_chunk(c + offset)
		var halo_l = l - offset * VoxelChunk.SIZE
		neighbor.set_density_halo(halo_l, d)
		neighbor.mark_dirty()


func set_material(p: Vector3i, m: int):
	var c = world_to_chunk(p)
	var l = world_to_local(p)
	
	if DEBUG:
		print("Adding material at p = ", p, " in chunk c = ", c, " with local coords l = ", l)

	var chunk = get_or_create_chunk(c)
	chunk.set_material(l, m)
	mark_chunk_dirty(c)
	
	
	# Propagate dirtiness to neighbors if on boundary
	var neighbor_offsets := get_boundary_neighbor_offsets(p)
	for offset in neighbor_offsets:
		var neighbor = get_or_create_chunk(c + offset)
		var halo_l = l - offset * VoxelChunk.SIZE
		neighbor.set_material_halo(halo_l, m)
		neighbor.mark_dirty()

func get_density(p: Vector3i) -> float:
	var c = world_to_chunk(p)
	var l = world_to_local(p)

	var chunk = get_or_create_chunk(c)
	return chunk.get_density(l)


func get_material(p: Vector3i) -> int:
	var c = world_to_chunk(p)
	var l = world_to_local(p)

	var chunk = get_or_create_chunk(c)
	return chunk.get_material(l)
	

func add_density_world(world_pos: Vector3, strength: float, radius: float, material_id: int = DEFAULT_MATERIAL, command: VoxelBrushCommand = null):
	var center := Vector3i(
		floor(world_pos.x),
		floor(world_pos.y),
		floor(world_pos.z)
	)
	var r   := int(ceil(radius))
	var r_f := float(radius)

	for x in range(center.x - r, center.x + r + 1):
		for y in range(center.y - r, center.y + r + 1):
			for z in range(center.z - r, center.z + r + 1):
				var p := Vector3i(x, y, z)
				var d := Vector3(p).distance_to(world_pos)

				# Check whether point is within brush radius and bounding box
				if d > r_f:
					continue
					
				# Calculate new density and material fields and record change
				var old_density  := get_density(p)
				var old_material := get_material(p)

				if command:
					command.record_before(p, old_density, old_material)

				var falloff      := 1.0 - (d / r_f)
				var delta        := strength * falloff
				var new_density  := old_density + delta
				var new_material := material_id if delta <= 0 else old_material # Only change material when adding density

				if command:
					command.record_after(p, new_density, new_material)

				# Update density and material fields
				set_density(p, new_density)
				set_material(p, new_material)

const MAX_MESHES_PER_FRAME := 2

func _process(_delta):
	if DEBUG:
		if dirty_chunks.size(): 
			print("There are ", dirty_chunks.size(), " dirty chunks before processing.")
			
	for i in range(min(MAX_MESHES_PER_FRAME, dirty_chunks.size())):
		var chunk = dirty_chunks.pop_front()
		if not is_instance_valid(chunk):
			continue

		if chunk.dirty:
			chunk.dirty = false  # <-- clear first
			chunk.generate_mesh()



func reset():
	for c in chunks.keys():
		chunks[c].queue_free()
	chunks.clear()
	dirty_chunks.clear()
