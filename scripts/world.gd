extends Node3D

const DEFAULT_MATERIAL := 0
var chunks := {}  # Dictionary<Vector3i, VoxelChunk>

func _ready():
	add_to_group("world")

func world_to_chunk(p: Vector3i) -> Vector3i:
	return Vector3i(
		floor(float(p.x) / float(VoxelChunk.SIZE)),
		floor(float(p.y) / float(VoxelChunk.SIZE)),
		floor(float(p.z) / float(VoxelChunk.SIZE))
	)

func world_to_local(p: Vector3i) -> Vector3i:
	return Vector3i(
		posmod(p.x, VoxelChunk.SIZE),
		posmod(p.y, VoxelChunk.SIZE),
		posmod(p.z, VoxelChunk.SIZE)
	)

func get_or_create_chunk(chunk_coord: Vector3i) -> VoxelChunk:
	if chunks.has(chunk_coord):
		return chunks[chunk_coord]
	

	var chunk := VoxelChunk.new()
	chunk.world       = self
	chunk.chunk_coord = chunk_coord
	chunk.position    = Vector3(chunk_coord) * VoxelChunk.SIZE
	add_child(chunk)

	chunks[chunk_coord] = chunk
	return chunk

func mark_chunk_dirty(chunk_coord: Vector3i):
	if chunks.has(chunk_coord):
		chunks[chunk_coord].mark_dirty()

func get_boundary_neighbor_offsets(l: Vector3i) -> Array[Vector3i]:
	var offsets: Array[Vector3i] = []

	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				if dx == 0 and dy == 0 and dz == 0:
					continue

				# Check if this neighbor samples this voxel
				if (dx == -1 and l.x == 0) or (dx == 1 and l.x == VoxelChunk.SIZE - 1) or dx == 0:
					if (dy == -1 and l.y == 0) or (dy == 1 and l.y == VoxelChunk.SIZE - 1) or dy == 0:
						if (dz == -1 and l.z == 0) or (dz == 1 and l.z == VoxelChunk.SIZE - 1) or dz == 0:
							offsets.append(Vector3i(dx, dy, dz))

	return offsets

func set_density(p: Vector3i, d: float):
	var c = world_to_chunk(p)
	var l = world_to_local(p)

	var chunk = get_or_create_chunk(c)
	chunk.set_density(l, d)
	chunk.mark_dirty()
	
	
	# Propagate dirtiness to neighbors if on boundary
	var neighbor_offsets := get_boundary_neighbor_offsets(l)
	for offset in neighbor_offsets:
		mark_chunk_dirty(c + offset)


func set_material(p: Vector3i, m: int):
	var c = world_to_chunk(p)
	var l = world_to_local(p)

	var chunk = get_or_create_chunk(c)
	chunk.set_material(l, m)
	chunk.mark_dirty()
	
	
	# Propagate dirtiness to neighbors if on boundary
	var neighbor_offsets := get_boundary_neighbor_offsets(l)
	for offset in neighbor_offsets:
		mark_chunk_dirty(c + offset)

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
