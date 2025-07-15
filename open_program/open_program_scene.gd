class_name OpenProgramScene
extends Control

@export var file_dialog: FileDialog

var wolf_file: FileAccess

var interpreter := Interpreter.new()

func _ready() -> void:
	file_dialog.file_selected.connect(_file_selected)
	file_dialog.show()
	
	interpreter.run("-3*7")
	interpreter.run("-3+7")
	interpreter.run("(7-3) % 5")
	interpreter.run("\"B\"+\"o\"+\"b\"")
	interpreter.run("12 or 4")
	interpreter.run("0 or 4")


func _file_selected(path: String):
	wolf_file = FileAccess.open(path, FileAccess.READ)
	interpreter.run(wolf_file.get_as_text())
