class_name ErrorHandler
extends RefCounted

var errors: Array[String]
var warnings: Array[String]

## A reference to the interpreter which created this
var interpreter: Interpreter


func _init() -> void:
	errors = []
	warnings = []


func report(line: int, where: String, message: String, is_error: bool) -> void:
	var error_prefix: String = "[Line %s] %s: " % [line, "Error" if is_error else "Warning"]
	var message_color: String = "#ff6f6c" if is_error else "#ffff77"
	var error_message: String = "[color=%s]%s%s[/color]" % [message_color, error_prefix, message]
	interpreter.console.println(error_message)
	
	if is_error:
		errors.append(error_message)
	else:
		warnings.append(error_message)


func error(line: int, message: String):
	report(line, "", message, true)


func warn(line: int, message: String):
	report(line, "", message, false)


func clear():
	errors = []
	warnings = []
