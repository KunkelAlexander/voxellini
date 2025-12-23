extends VBoxContainer


func _ready():
	if OS.has_feature("web"):
		$Exit.visible = false
