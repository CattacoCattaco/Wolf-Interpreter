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
	
	console.println("Input: " + code)
	
	var lexer := Lexer.new(code)
	lexer.interpreter = self
	
	var tokens: Array[Token] = lexer.scan_tokens()
	
	#var token_string: String = ""
	#for token: Token in tokens:
		#token_string += "%s " % token
	#
	#print(token_string)
	#
	#print("\n")
	
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
	
	console.println("Parsed: " + str(expr))
	
	var evaluator := Evaluator.new()
	evaluator.interpreter = self
	
	var result = evaluator.evaluate_expr(expr)["value"]
	console.println("Result: " + str(result))
	
	console.println("\n")
