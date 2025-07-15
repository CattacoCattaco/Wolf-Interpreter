class_name OpenProgramScene
extends Control

@export var file_dialog: FileDialog

var wolf_file: FileAccess

var interpreter := Interpreter.new()

func _ready() -> void:
	file_dialog.file_selected.connect(_file_selected)
	file_dialog.show()
	
	interpreter.run("-*7")
	interpreter.run("-3*7")
	interpreter.run("-3+7")
	interpreter.run("(7-3) % 5")
	interpreter.run("\"B\"+\"o\"+\"b\"")
	interpreter.run("12 || 4")
	interpreter.run("0 or 4")
	interpreter.run("'a' + 1")
	interpreter.run("'a' * 6 + 5 / 3")
	interpreter.run("'a' * 6 + 5 / 3.0")
	interpreter.run("true^^true")
	interpreter.run("1 < 3 nor 2 == 2")
	interpreter.run("1 < 3 xnor 2 == 2")
	interpreter.run("or 3")
	interpreter.run("5 * 7 +")
	interpreter.run("5 * 7 + ()")
	interpreter.run("@3 + * 7")


func _file_selected(path: String):
	wolf_file = FileAccess.open(path, FileAccess.READ)
	interpreter.run(wolf_file.get_as_text())
