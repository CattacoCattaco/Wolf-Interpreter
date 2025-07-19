class_name OpenProgramScene
extends Control

@export var _file_dialog: FileDialog
@export var _console: Console

@export var _code_edit: CodeEdit

@export var _open_from_file_button: Button
@export var _run_button: Button
@export var _clear_console_button: Button
@export var _open_manual_button: Button
@export var _close_manual_button: Button

@export var manual: ColorRect

var wolf_file: FileAccess

@onready var interpreter := Interpreter.new(_console)

func _ready() -> void:
	if OS.has_feature("debug"):
		interpreter.run("print(-*7)")
		interpreter.run("print(-3*7)")
		interpreter.run("print(-3+7)")
		interpreter.run("print((7-3) % 5)")
		interpreter.run("print(\"B\"+\"o\"+\"b\")")
		interpreter.run("print(12 || 4)")
		interpreter.run("print(0 or 4)")
		interpreter.run("print('a' + 1)")
		interpreter.run("print('a' * 6 + 5 / 3)")
		interpreter.run("print('a' * 6 + 5 / 3.0)")
		interpreter.run("print(true^^true)")
		interpreter.run("print(1 < 3 nor 2 == 2)")
		interpreter.run("print(1 < 3 xnor 2 == 2)")
		interpreter.run("print(or 3)")
		interpreter.run("print(5 * 7 +)")
		interpreter.run("print(5 * 7 + ())")
		interpreter.run("print(@3 + * 7)")
		interpreter.run("print(5 as bool)")
		interpreter.run("print(true as int)")
		interpreter.run("int i = 'a'\nprint(i)")
		interpreter.run("int i\nprint(i)")
		interpreter.run("int i\ni = 'a'\nprint(i)")
	
	if OS.has_feature("web"):
		_open_from_file_button.hide()
	else:
		_file_dialog.file_selected.connect(_file_selected)
		_open_from_file_button.pressed.connect(_file_dialog.show)
	
	_run_button.pressed.connect(_run)
	_clear_console_button.pressed.connect(_console.clear)
	_open_manual_button.pressed.connect(manual.show)
	_close_manual_button.pressed.connect(manual.hide)


func _file_selected(path: String):
	wolf_file = FileAccess.open(path, FileAccess.READ)
	_code_edit.text = wolf_file.get_as_text()


func _run():
	interpreter.run(_code_edit.text)
