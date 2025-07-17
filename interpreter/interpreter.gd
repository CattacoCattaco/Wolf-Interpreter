class_name Interpreter
extends RefCounted

var console: Console
var error_handler: ErrorHandler


func _init(p_console: Console) -> void:
	console = p_console
	console.interpreter = self
	
	error_handler = ErrorHandler.new()
	error_handler.interpreter = self


func run(code: String) -> void:
	error_handler.clear()
	
	if OS.has_feature("debug"):
		console.println("Input: " + code)
	
	var lexer := Lexer.new(code)
	lexer.interpreter = self
	
	var tokens: Array[Token] = lexer.scan_tokens()
	
	if OS.has_feature("debug"):
		var token_string: String = "Tokens: "
		for token: Token in tokens:
			token_string += "%s " % token
		
		console.println(token_string)
	
	# Exit early if errors present
	if error_handler.errors:
		console.println("\n")
		return
	
	var parser := Parser.new(tokens)
	parser.interpreter = self
	
	var expr: Expr = parser.parse()
	
	# Exit early if errors present
	if error_handler.errors or not expr:
		console.println("\n")
		return
	
	if OS.has_feature("debug"):
		console.println("Parsed: " + str(expr))
	
	var typer := Typer.new()
	typer.interpreter = self
	
	var typed_expr: Expr = typer.type_check(expr)
	
	# Exit early if errors present
	if error_handler.errors:
		console.println("\n")
		return
	
	if OS.has_feature("debug"):
		console.println("Typed: " + str(typed_expr))
	
	var evaluator := Evaluator.new()
	evaluator.interpreter = self
	
	var result: Dictionary = evaluator.evaluate_expr(typed_expr)
	
	if not error_handler.errors:
		if result.has("value"):
			console.println("Result: " + str(result["value"]))
	
	console.println("\n")
