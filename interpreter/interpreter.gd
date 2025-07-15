class_name Interpreter
extends RefCounted

var error_handler: ErrorHandler


func _init() -> void:
	error_handler = ErrorHandler.new()


func run(code: String) -> void:
	error_handler.clear()
	
	print("Input: ", code)
	
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
		print("\n")
		return
	
	var parser := Parser.new(tokens)
	parser.interpreter = self
	
	var expr: Expr = parser.parse()
	
	# Exit early if errors present
	if error_handler.errors or not expr:
		print("\n")
		return
	
	print("Parsed: ", expr)
	
	var evaluator := Evaluator.new()
	evaluator.interpreter = self
	
	var result = evaluator.evaluate_expr(expr)["value"]
	print("Result: ", result)
	
	print("\n")
