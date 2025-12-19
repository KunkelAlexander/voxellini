extends Node

enum Mode { GAMEPLAY, MENU }
var mode := Mode.GAMEPLAY

signal mode_changed(new_mode)
signal world_loaded(world)

var pause_menu: CanvasLayer
func _ready():
	_apply_mouse_mode()

func set_mode(new_mode: Mode):
	if mode == new_mode:
		return
	mode = new_mode
	_apply_mouse_mode()
	emit_signal("mode_changed", mode)
	
	
func _unhandled_input(event):
	if event.is_action_pressed("exit"):
		if mode == Mode.GAMEPLAY:
			set_mode(Mode.MENU)
		else:
			set_mode(Mode.GAMEPLAY)
			
func _apply_mouse_mode():
	match mode:
		Mode.GAMEPLAY:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		Mode.MENU:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			

func get_world() -> Node:
	return get_tree().get_first_node_in_group("world")
	
func save_world():
	var world = get_world()
	if world:
		SaveManager.save_world_to_file(world, "user://world.json")
	

func load_world():
	var world = get_world()
	if world:
		SaveManager.load_world_from_file(world, "user://world.json")

		# Let other components know 
		emit_signal("world_loaded", world)
