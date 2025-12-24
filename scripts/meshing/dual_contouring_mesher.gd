class_name DualContouringMesher
extends VoxelMesher


const EDGE_DIRS = [
	Vector3i(1, 0, 0),
	Vector3i(0, 1, 0),
	Vector3i(0, 0, 1)
]

const CELL_EDGES = [
	# edges parallel to X
	[Vector3i(0,0,0), Vector3i(1,0,0)],
	[Vector3i(0,1,0), Vector3i(1,1,0)],
	[Vector3i(0,0,1), Vector3i(1,0,1)],
	[Vector3i(0,1,1), Vector3i(1,1,1)],

	# edges parallel to Y
	[Vector3i(0,0,0), Vector3i(0,1,0)],
	[Vector3i(1,0,0), Vector3i(1,1,0)],
	[Vector3i(0,0,1), Vector3i(0,1,1)],
	[Vector3i(1,0,1), Vector3i(1,1,1)],

	# edges parallel to Z
	[Vector3i(0,0,0), Vector3i(0,0,1)],
	[Vector3i(1,0,0), Vector3i(1,0,1)],
	[Vector3i(0,1,0), Vector3i(0,1,1)],
	[Vector3i(1,1,0), Vector3i(1,1,1)],
]

func generate(chunk, vertices, normals, colors):
	var cell_vertex = {}

	for x in range(chunk.SIZE_X):
		for y in range(chunk.SIZE_Y):
			for z in range(chunk.SIZE_Z):
				var p = Vector3i(x, y, z)
				var v = compute_cell_vertex(chunk, p)
				if v != null:
					cell_vertex[p] = v

	emit_faces(chunk, cell_vertex, vertices, normals, colors)


func compute_cell_vertex(chunk, p: Vector3i):
	var intersections = []

	for edge in CELL_EDGES:
		var p0 = p + edge[0]
		var p1 = p + edge[1]

		var d0 = chunk.get_density(p0)
		var d1 = chunk.get_density(p1)

		if (d0 <= chunk.ISO_LEVEL and d1 > chunk.ISO_LEVEL) \
		or (d1 <= chunk.ISO_LEVEL and d0 > chunk.ISO_LEVEL):
			var t = (d0 - chunk.ISO_LEVEL) / (d0 - d1)
			var pos = Vector3(p0).lerp(Vector3(p1), t)
			intersections.append(pos)

	if intersections.is_empty():
		return null

	var avg = Vector3.ZERO
	for v in intersections:
		avg += v
	avg /= intersections.size()

	return avg


func emit_faces(chunk, cell_vertex, vertices, normals, colors):
	var size_x = chunk.SIZE_X
	var size_y = chunk.SIZE_Y
	var size_z = chunk.SIZE_Z

	# X-aligned edges
	for x in range(size_x):
		for y in range(size_y):
			for z in range(size_z + 1):
				_emit_edge_quad(
					chunk,
					Vector3i(x, y, z),
					Vector3i(1, 0, 0),
					cell_vertex,
					vertices, normals, colors
				)

	# Y-aligned edges
	for x in range(size_x):
		for y in range(size_y + 1):
			for z in range(size_z):
				_emit_edge_quad(
					chunk,
					Vector3i(x, y, z),
					Vector3i(0, 1, 0),
					cell_vertex,
					vertices, normals, colors
				)

	# Z-aligned edges
	for x in range(size_x + 1):
		for y in range(size_y):
			for z in range(size_z):
				_emit_edge_quad(
					chunk,
					Vector3i(x, y, z),
					Vector3i(0, 0, 1),
					cell_vertex,
					vertices, normals, colors
				)

func _emit_edge_quad(
	chunk,
	p: Vector3i,
	dir: Vector3i,
	cell_vertex,
	vertices, normals, colors
):
	var d0 = chunk.get_density(p)
	var d1 = chunk.get_density(p + dir)

	if (d0 <= chunk.ISO_LEVEL and d1 <= chunk.ISO_LEVEL) \
	or (d0 > chunk.ISO_LEVEL and d1 > chunk.ISO_LEVEL):
		return

	# Collect the 4 cells sharing this edge
	var cells = [
		p - Vector3i(0, 0, 0),
		p - Vector3i(dir.y, dir.z, dir.x),
		p - Vector3i(dir.z, dir.x, dir.y),
		p - Vector3i(dir.y + dir.z, dir.z + dir.x, dir.x + dir.y)
	]

	var verts := []
	for c in cells:
		if not cell_vertex.has(c):
			return
		verts.append(cell_vertex[c])

	var normal = ((verts[1] - verts[0]).cross(verts[2] - verts[0])).normalized()
	var color = chunk.material_id_to_color(chunk.get_material(cells[0]))

	emit_quad(
		verts[0], verts[1], verts[3], verts[2],
		normal, color,
		vertices, normals, colors
	)
func emit_quad(a, b, c, d, normal, color, vertices, normals, colors):
	vertices.append(a)
	vertices.append(c)
	vertices.append(b)

	vertices.append(a)
	vertices.append(d)
	vertices.append(c)

	for i in range(6):
		normals.append(normal)
		colors.append(color)
