class_name Interpreter
extends RefCounted

var console: Console
var game: Game

var error_handler: ErrorHandler
var environment: WolfEnvironment

var do_debug: bool = false

var last_evaluator: Evaluator


func _init(p_console: Console, p_game: Game) -> void:
	if not Typer.data_types:
		Typer.load_data_types()
	
	console = p_console
	console.interpreter = self
	
	game = p_game
	
	error_handler = ErrorHandler.new()
	error_handler.interpreter = self
	
	if not OS.has_feature("debug"):
		do_debug = false


func add_globals() -> void:
	for i in range(10):
		environment.types["KEYCODE_" + char(48 + i)] = Typer.data_types["int"]
		environment.values["KEYCODE_" + char(48 + i)] = WolfInt.new(48 + i)
	
	for i in range(26):
		environment.types["KEYCODE_" + char(65 + i)] = Typer.data_types["int"]
		environment.values["KEYCODE_" + char(65 + i)] = WolfInt.new(65 + i)
	
	environment.types["clear_console"] = Typer.data_types["callable"]
	environment.values["clear_console"] = ClearConsole.new(self)
	
	environment.types["print"] = Typer.data_types["callable"]
	environment.values["print"] = Print.new(self)
	
	environment.types["prompt"] = Typer.data_types["callable"]
	environment.values["prompt"] = Prompt.new(self)
	
	environment.types["wait"] = Typer.data_types["callable"]
	environment.values["wait"] = Wait.new(self)
	
	environment.types["set_cell_bg_color"] = Typer.data_types["callable"]
	environment.values["set_cell_bg_color"] = SetCellBGColor.new(self)
	
	environment.types["set_cell_char_color"] = Typer.data_types["callable"]
	environment.values["set_cell_char_color"] = SetCellCharColor.new(self)
	
	environment.types["set_cell_char"] = Typer.data_types["callable"]
	environment.values["set_cell_char"] = SetCellChar.new(self)
	
	environment.types["is_key_down"] = Typer.data_types["callable"]
	environment.values["is_key_down"] = IsKeyDown.new(self)


func run(code: String) -> void:
	if last_evaluator:
		last_evaluator.stop()
	
	error_handler.clear()
	environment = WolfEnvironment.new()
	
	add_globals()
	
	game.cell_grid.grid_size = 16
	game.cell_grid.load_grid()
	
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
	
	last_evaluator = evaluator
	
	await evaluator.evaluate_statements(statements)
	
	if do_debug:
		console.println("\n")
