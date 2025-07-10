class_name OpenProgramScene
extends Control

@export var file_dialog: FileDialog

@onready var wolf_file: FileAccess

func _ready() -> void:
	file_dialog.file_selected.connect(_file_selected)
	file_dialog.show()


func _file_selected(path: String):
	wolf_file = FileAccess.open(path, FileAccess.READ)
	print(wolf_file.get_line())
