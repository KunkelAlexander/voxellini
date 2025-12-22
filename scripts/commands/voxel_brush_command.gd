extends VoxelCommand
class_name VoxelBrushCommand

var before := {}
var after := {}

func record_before(p: Vector3i, d, m):
	if not before.has(p):
		before[p] = { "density": d, "material": m }

func record_after(p: Vector3i, d, m):
	after[p] = { "density": d, "material": m }

func execute(terrain):
	for p in after.keys():
		var s = after[p]
		terrain.set_density(p, s.density)
		terrain.set_material(p, s.material)

func undo(terrain):
	for p in before.keys():
		var s = before[p]
		terrain.set_density(p, s.density)
		terrain.set_material(p, s.material)
		
