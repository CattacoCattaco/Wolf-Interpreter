class_name Console
extends RichTextLabel

@export var input_line: LineEdit

## A reference to the interpreter
var interpreter: Interpreter


func _ready() -> void:
	input_line.text_submitted.connect(submit_input)


func println(print_text: String, end: String = "\n") -> void:
	append_text(print_text + end)


func clear_text() -> void:
	text = ""
	input_line.text = ""


func submit_input(new_text: String) -> void:
	println(new_text)
	input_line.text = ""
