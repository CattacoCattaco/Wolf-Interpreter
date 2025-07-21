class_name Interpreter
extends RefCounted

var console: Console
var error_handler: ErrorHandler
var environment: WolfEnvironment

var do_debug: bool = false


func _init(p_console: Console) -> void:
	console = p_console
	console.interpreter = self
	
	error_handler = ErrorHandler.new()
	error_handler.interpreter = self
	
	if not OS.has_feature("debug"):
		do_debug = false


func run(code: String) -> void:
	error_handler.clear()
	environment = WolfEnvironment.new()
	
	environment.types["clear_console"] = "callable"
	environment.values["clear_console"] = ClearConsole.new(self)
	
	environment.types["print"] = "callable"
	environment.values["print"] = Print.new(self)
	
	environment.types["prompt"] = "callable"
	environment.values["prompt"] = Prompt.new(self)
	
	if do_debug:
		console.println("Input: " + code)
	
	var lexer := Lexer.new(code)
	lexer.interpreter = self
	
	var tokens: Array[Token] = lexer.scan_tokens()
	
	# Exit early if errors present
	if error_handler.errors:
		if do_debug:
			console.println("\n")
		return
	
	if do_debug:
		var token_string: String = "Tokens: "
		for token: Token in tokens:
			token_string += "%s " % token
		
		console.println(token_string)
	
	var parser := Parser.new(tokens)
	parser.interpreter = self
	
	var statements: Array[Statement] = parser.parse()
	
	# Exit early if errors present
	if error_handler.errors:
		if do_debug:
			console.println("\n")
		return
	
	if do_debug:
		console.println("Parsed: ", "")
		
		for statement in statements:
			console.println(str(statement))
	
	var typer := Typer.new()
	typer.interpreter = self
	
	typer.type_check_statements(statements)
	
	# Exit early if errors present
	if error_handler.errors:
		if do_debug:
			console.println("\n")
		return
	
	if do_debug:
		console.println("Typed: ", "")
		for statement in statements:
			console.println(str(statement))
	
	var evaluator := Evaluator.new()
	evaluator.interpreter = self
	
	await evaluator.evaluate_statements(statements)
	
	if do_debug:
		console.println("\n")
