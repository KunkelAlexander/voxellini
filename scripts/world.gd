extends Node3D

const DEFAULT_MATERIAL := 0
var chunks := {}  # Dictionary<Vector3i, VoxelChunk>

func _ready():
	add_to_group("world")
	
	print("\n==============================")
	print(" VOXEL WORLD DEBUG START ")
	print("==============================\n")

	# --------------------------------------------------
	# 1) Force-create a small grid of chunks around origin
	# --------------------------------------------------
	print("Creating test chunks...")
	for x in range(-1, 3):
		for y in range(0, 1):
			for z in range(0, 1):
				get_or_create_chunk(Vector3i(x, y, z))

	# --------------------------------------------------
	# 2) Walk across chunk boundaries (world → chunk)
	# --------------------------------------------------
	print("\n[TEST] Walking +X axis across chunks")
	debug_walk_axis(
		Vector3i(0, 0, 0),
		Vector3i(1, 0, 0),
		64
	)

	print("\n[TEST] Walking -X axis across chunks")
	debug_walk_axis(
		Vector3i(0, 0, 0),
		Vector3i(-1, 0, 0),
		64
	)

	# --------------------------------------------------
	# 3) Round-trip consistency checks
	# --------------------------------------------------
	print("\n[TEST] Round-trip world → chunk → local → world")
	var test_points := [
		Vector3i(0, 0, 0),
		Vector3i(15, 0, 0),
		Vector3i(16, 0, 0),
		Vector3i(31, 0, 0),
		Vector3i(32, 0, 0),
		Vector3i(-1, 0, 0),
		Vector3i(-16, 0, 0),
		Vector3i(-17, 0, 0),
	]

	for p in test_points:
		debug_round_trip(p)

	# --------------------------------------------------
	# 4) Verify chunk ownership and transforms
	# --------------------------------------------------
	print("\n[TEST] Chunk responsibilities & node positions")
	debug_chunk_responsibilities()

	# --------------------------------------------------
	# 5) Border density agreement tests
	# --------------------------------------------------
	print("\n[TEST] Border density agreement (+X)")
	debug_border_density(
		Vector3i(0, 0, 0),
		Vector3i(1, 0, 0),
		Vector3i(1, 0, 0)
	)

	print("\n[TEST] Border density agreement (-X)")
	debug_border_density(
		Vector3i(-1, 0, 0),
		Vector3i(0, 0, 0),
		Vector3i(1, 0, 0)
	)

	# --------------------------------------------------
	# 6) Visual sanity check (optional but powerful)
	# --------------------------------------------------
	print("\n[TEST] Coloring chunks for visual inspection")
	debug_color_chunks()

	print("\n==============================")
	print(" VOXEL WORLD DEBUG COMPLETE ")
	print("==============================\n")


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

func set_density(p: Vector3i, d: float):
	var c = world_to_chunk(p)
	var l = world_to_local(p)

	var chunk = get_or_create_chunk(c)
	chunk.set_density(l, d)
	chunk.mark_dirty()


func set_material(p: Vector3i, m: int):
	var c = world_to_chunk(p)
	var l = world_to_local(p)

	var chunk = get_or_create_chunk(c)
	chunk.set_material(l, m)
	chunk.mark_dirty()

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

func debug_walk_axis(
	start: Vector3i,
	dir: Vector3i,
	steps: int = 64
):
	print("\n=== DEBUG WALK ===")
	print("Start:", start, " Dir:", dir, " Steps:", steps)

	var last_chunk := Vector3i(999999, 999999, 999999)

	for i in range(steps + 1):
		var p := start + dir * i
		var c := world_to_chunk(p)
		var l := world_to_local(p)

		if c != last_chunk:
			print(
				"STEP", i,
				" WORLD", p,
				" → CHUNK", c,
				" (chunk origin =", c * VoxelChunk.SIZE, ")"
			)
			last_chunk = c

		print(
			"   p =", p,
			" local =", l
		)
func debug_round_trip(p: Vector3i):
	var c := world_to_chunk(p)
	var l := world_to_local(p)
	var reconstructed := c * VoxelChunk.SIZE + l

	print(
		"ROUND TRIP:",
		"world =", p,
		"chunk =", c,
		"local =", l,
		"reconstructed =", reconstructed,
		"OK =", reconstructed == p
	)
func debug_chunk_responsibilities():
	print("\n=== CHUNK RESPONSIBILITIES ===")
	for c in chunks.keys():
		var min_world = c * VoxelChunk.SIZE
		var max_world = min_world + Vector3i(
			VoxelChunk.SIZE - 1,
			VoxelChunk.SIZE - 1,
			VoxelChunk.SIZE - 1
		)

		print(
			"Chunk", c,
			"owns world [",
			min_world, "→", max_world, "]",
			"node position =", chunks[c].position
		)
func debug_border_density(c0: Vector3i, c1: Vector3i, axis: Vector3i):
	print("\n=== BORDER DENSITY TEST ===")
	print("Chunks:", c0, "<->", c1, "axis", axis)

	var chunk0 := get_or_create_chunk(c0)
	var chunk1 := get_or_create_chunk(c1)

	for i in range(VoxelChunk.SIZE):
		var p0 := Vector3i(
			VoxelChunk.SIZE,
			i,
			i
		)
		var world_p := c0 * VoxelChunk.SIZE + p0

		var d0 := chunk0.get_density_local_or_world(p0)
		var d1 := chunk1.get_density_local_or_world(
			Vector3i(0, i, i)
		)

		if d0 != d1:
			print(
				"❌ MISMATCH at world", world_p,
				"d0 =", d0,
				"d1 =", d1
			)
func debug_color_chunks():
	for c in chunks.keys():
		var chunk = chunks[c]
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(
			fmod(abs(c.x) * 0.2, 1.0),
			fmod(abs(c.y) * 0.2, 1.0),
			fmod(abs(c.z) * 0.2, 1.0)
		)
		chunk.mesh_instance.material_override = mat
