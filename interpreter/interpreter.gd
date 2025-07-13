class_name Interpreter
extends RefCounted

var error_handler: ErrorHandler


func _init() -> void:
	error_handler = ErrorHandler.new()


func run(code: String) -> void:
	var lexer: Lexer = Lexer.new(code)
	lexer.interpreter = self
	
	var tokens: Array[Token] = lexer.scan_tokens()
	
	for token: Token in tokens:
		print(token, " ")
