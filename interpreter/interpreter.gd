class_name Interpreter
extends RefCounted

var console: Console
var error_handler: ErrorHandler
var environment: WolfEnvironment


func _init(p_console: Console) -> void:
	console = p_console
	console.interpreter = self
	
	error_handler = ErrorHandler.new()
	error_handler.interpreter = self


func run(code: String) -> void:
	error_handler.clear()
	environment = WolfEnvironment.new()
	
	if OS.has_feature("debug"):
		console.println("Input: " + code)
	
	var lexer := Lexer.new(code)
	lexer.interpreter = self
	
	var tokens: Array[Token] = lexer.scan_tokens()
	
	# Exit early if errors present
	if error_handler.errors:
		console.println("\n")
		return
	
	if OS.has_feature("debug"):
		var token_string: String = "Tokens: "
		for token: Token in tokens:
			token_string += "%s " % token
		
		console.println(token_string)
	
	var parser := Parser.new(tokens)
	parser.interpreter = self
	
	var statements: Array[Statement] = parser.parse()
	
	# Exit early if errors present
	if error_handler.errors:
		console.println("\n")
		return
	
	if OS.has_feature("debug"):
		console.println("Parsed: ", "")
		
		for statement in statements:
			console.println(str(statement))
	
	var typer := Typer.new()
	typer.interpreter = self
	
	typer.type_check_statements(statements)
	
	# Exit early if errors present
	if error_handler.errors:
		console.println("\n")
		return
	
	if OS.has_feature("debug"):
		console.println("Typed: ", "")
		for statement in statements:
			console.println(str(statement))
	
	var evaluator := Evaluator.new()
	evaluator.interpreter = self
	
	evaluator.evaluate_statements(statements)
	
	console.println("\n")
