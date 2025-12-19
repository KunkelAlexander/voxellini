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
	var density := {}
	for p in world.get_density_field().keys():
		density[v3i_to_key(p)] = world.get_density_field()[p]

	var material := {}
	for p in world.get_material_field().keys():
		material[v3i_to_key(p)] = world.get_material_field()[p]

	return {
		"version": 1,
		"density": density,
		"material": material
	}

func deserialize_world(world: Node, data: Dictionary):
	var density := {}
	for key in data["density"]:
		density[key_to_v3i(key)] = float(data["density"][key])

	var material := {}
	for key in data["material"]:
		material[key_to_v3i(key)] = int(data["material"][key])

	world.set_density_field(density)
	world.set_material_field(material)
	world.generate_mesh()
	
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
