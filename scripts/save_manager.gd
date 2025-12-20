extends Node

func v3i_to_key(v: Vector3i) -> String:
	return "%d,%d,%d" % [v.x, v.y, v.z]

func key_to_v3i(s: String) -> Vector3i:
	var parts = s.split(",")
	return Vector3i(
		int(parts[0]),
		int(parts[1]),
		int(parts[2])
	)
func serialize_world(world: Node) -> Dictionary:
	var chunks_data := {}

	for chunk_coord in world.chunks.keys():
		var chunk = world.chunks[chunk_coord]

		var density := {}
		for p in chunk.get_density_field().keys():
			density[v3i_to_key(p)] = chunk.get_density_field()[p]

		var material := {}
		for p in chunk.get_material_field().keys():
			material[v3i_to_key(p)] = chunk.get_material_field()[p]

		# Only store non-empty chunks
		if density.size() > 0 or material.size() > 0:
			chunks_data[v3i_to_key(chunk_coord)] = {
				"density": density,
				"material": material
			}


	# ---- PALETTE SERIALIZATION ----
	var palette_data := {}
	for id in MaterialPalette.colors.keys():
		palette_data[str(id)] = color_to_data(MaterialPalette.colors[id])

	return {
		"version": 2, # bump version
		"palette": palette_data,
		"chunks": chunks_data
	}


func deserialize_world(world: Node, data: Dictionary):
	assert(data.has("chunks"), "Invalid world save data")

	# Clear existing chunks
	world.reset()

	# ---- PALETTE DESERIALIZATION ----
	if data.has("palette"):
		MaterialPalette.colors.clear()

		var max_id := -1
		for key in data["palette"].keys():
			var id := int(key)
			var col := data_to_color(data["palette"][key])
			MaterialPalette.colors[id] = col
			max_id = max(max_id, id)

		MaterialPalette._next_id = max_id + 1
		MaterialPalette.palette_changed.emit(-1)
	
	for chunk_key in data["chunks"].keys():
		var chunk_coord := key_to_v3i(chunk_key)
		var chunk_data = data["chunks"][chunk_key]

		var chunk = world.get_or_create_chunk(chunk_coord)

		var density := {}
		for key in chunk_data["density"]:
			density[key_to_v3i(key)] = float(chunk_data["density"][key])

		var material := {}
		for key in chunk_data["material"]:
			material[key_to_v3i(key)] = int(chunk_data["material"][key])

		chunk.set_density_field(density)
		chunk.set_material_field(material)
		chunk.mark_dirty()

func save_world_to_file(world: Node, path: String):
	var data = serialize_world(world)
	var json = JSON.stringify(data)

	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(json)
	file.close()
	
func load_world_from_file(world: Node, path: String):
	if not FileAccess.file_exists(path):
		push_error("Save file not found")
		return

	var file = FileAccess.open(path, FileAccess.READ)
	var json = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid save file")
		return

	deserialize_world(world, parsed)
	
func color_to_data(c: Color) -> Array:
	return [c.r, c.g, c.b, c.a]

func data_to_color(a: Array) -> Color:
	return Color(a[0], a[1], a[2], a[3])
