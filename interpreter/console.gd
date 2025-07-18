class_name Console
extends RichTextLabel

## A reference to the interpreter which created this
var interpreter: Interpreter


func println(print_text: String, end: String = "\n") -> void:
	append_text(print_text + end)


func clear_text() -> void:
	text = ""
