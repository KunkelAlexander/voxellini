extends CanvasLayer

func _ready():
	Game.mode_changed.connect(_on_mode_changed)
	visible = false

func _on_mode_changed(mode):
	visible = (mode == Game.Mode.MENU)

	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
func _on_resume_pressed():
	Game.set_mode(Game.Mode.GAMEPLAY)

func _on_save_pressed():
	print("Save world (TODO)")

func _on_load_pressed():
	print("Load world (TODO)")
	
func _on_quit_pressed():
	get_tree().quit()
