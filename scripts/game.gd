extends Node

enum Mode {
	GAMEPLAY,
	MENU,
	MATERIAL_PICKER
}
var mode := Mode.MENU

signal mode_changed(new_mode)
signal world_loaded(world)
signal world_reset(world)

var pause_menu: CanvasLayer
var had_mouse_capture := false
var capture_requested := false
func _ready():
	_apply_mouse_mode()
	
	#var window := get_window()
	#window.focus_exited.connect(_on_window_focus_lost)
	#window.focus_entered.connect(_on_window_focus_gained)


func set_mode(new_mode: Mode):
	if mode == new_mode:
		return
	mode = new_mode
	
	
	if mode == Mode.GAMEPLAY:
		capture_requested = true
		had_mouse_capture = false
	else:
		capture_requested = false
		had_mouse_capture = false

	_apply_mouse_mode()
	emit_signal("mode_changed", mode)
	

func _unhandled_input(event):
	if event.is_action_pressed("exit"):
		match mode:
			Mode.GAMEPLAY:
				set_mode(Mode.MENU)

			Mode.MATERIAL_PICKER:
				set_mode(Mode.GAMEPLAY)

			Mode.MENU:
				set_mode(Mode.GAMEPLAY)
			
func _process(_delta):
	if mode != Mode.GAMEPLAY:
		had_mouse_capture = false
		return

	var captured := Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED


	if captured:
		had_mouse_capture = true
		capture_requested = false
		return

	# Mouse not captured yet - request some more
	# Ignore while we are still waiting for the browser
	if capture_requested:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)		
		return

	# Only now is this a *real* capture loss
	if had_mouse_capture:
		set_mode(Mode.MENU)
		

func _apply_mouse_mode():
	match mode:
		Mode.GAMEPLAY:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		Mode.MENU:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		Mode.MATERIAL_PICKER:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)



func get_world() -> Node:
	return get_tree().get_first_node_in_group("world")
	
func save_world(filename):
	var world = get_world()
	if world:
		SaveManager.save_world_to_file(world, filename)
	

func load_world(filename):
	var world = get_world()
	if world:
		SaveManager.load_world_from_file(world, filename)

		# Let other components know 
		emit_signal("world_loaded", world)

func reset_world():
	var world = get_world()
	if world:
		
		world.reset()
		# Let other components know 
		emit_signal("world_reset", world)
	
	
