class_name OpenProgramScene
extends Control

@export var file_dialog: FileDialog

var wolf_file: FileAccess

var interpreter := Interpreter.new()

func _ready() -> void:
	file_dialog.file_selected.connect(_file_selected)
	file_dialog.show()


func _file_selected(path: String):
	wolf_file = FileAccess.open(path, FileAccess.READ)
	print(wolf_file.get_line())
	interpreter.errorHandler.error(1, "Bad Thing")
	interpreter.errorHandler.warn(2, "Odd Thing")
