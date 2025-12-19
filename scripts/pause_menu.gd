extends CanvasLayer

@onready var file_dialog: FileDialog = $FileDialog

enum FileAction { SAVE, LOAD }
var pending_action: FileAction

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
	pending_action = FileAction.SAVE
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.popup_centered()

func _on_load_pressed():
	pending_action = FileAction.LOAD
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.popup_centered()
	
func _on_quit_pressed():
	get_tree().quit()


func _on_file_dialog_file_selected(path: String) -> void:
	match pending_action:
		FileAction.SAVE:
			Game.save_world(path)

		FileAction.LOAD:
			Game.load_world(path)
