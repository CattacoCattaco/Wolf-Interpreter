class_name Interpreter
extends RefCounted

var errorHandler: ErrorHandler


func _init() -> void:
	errorHandler = ErrorHandler.new()
