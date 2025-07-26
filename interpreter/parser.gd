class_name Parser
extends RefCounted

var tokens: Array[Token]
var current: int = 0

## A reference to the interpreter which created this
var interpreter: Interpreter

var current_env: WolfEnvironment


func _init(p_tokens: Array[Token]) -> void:
	tokens = p_tokens


func _is_at_end() -> bool:
	return _peek().token_type == Token.EOF


func _peek() -> Token:
	return tokens[current]


func _advance() -> Token:
	var ret_token: Token = _peek()
	
	if not _is_at_end():
		current += 1
	
	return ret_token


func _primary() -> Expr:
	if _peek().token_type == Token.LITERAL:
		return Expr.Literal.new(_advance())
	
	if _peek().token_type == Token.IDENTIFIER:
		if not current_env.var_has_type(_peek().lexeme):
			var msg: String = "Variable %s not yet defined" % _peek().lexeme
			interpreter.error_handler.error(_peek().line_num, msg)
			return null
		
		return Expr.Variable.new(_advance())
	
	if _peek().token_type == Token.OPEN_PAREN:
		# Consume openning paren
		_advance()
		
		var expr: Expr = _expression()
		
		if _peek().token_type == Token.CLOSE_PAREN:
			if not expr:
				return null
			
			_advance()
			return expr
		else:
			interpreter.error_handler.error(_peek().line_num, "Unclosed parentheses")
			return null
	
	_advance()
	interpreter.error_handler.error(_peek().line_num, "Expression expected")
	
	return null


func _call() -> Expr:
	var expr: Expr = _primary()
	
	while _peek().token_type == Token.OPEN_PAREN:
		var paren_token: Token = _advance()
		
		var arguments: Array[Expr] = []
		
		while _peek().token_type != Token.CLOSE_PAREN and not _is_at_end():
			var arg: Expr = _expression()
			
			if not arg:
				return null
			
			arguments.append(arg)
			
			# Consume the comma unless this is last arg
			if _peek().token_type == Token.COMMA:
				_advance()
			elif _peek().token_type == Token.CLOSE_PAREN:
				pass
			else:
				var msg: String = "',' expected between arguments"
				interpreter.error_handler.error(paren_token.line_num, msg)
				return null
		
		var close_paren_token: Token
		# Consume the ')'
		if _peek().token_type == Token.CLOSE_PAREN:
			close_paren_token = _advance()
		else:
			var msg: String = "')' expected after arguments"
			interpreter.error_handler.error(paren_token.line_num, msg)
			return null
		
		if len(arguments) > 255:
			var msg: String = "Can't have more than 255 arguments"
			interpreter.error_handler.error(close_paren_token.line_num, msg)
		
		expr = Expr.Call.new(expr, close_paren_token, arguments)
	
	return expr


func _unary() -> Expr:
	if _peek().token_type in [Token.BIT_NOT, Token.MINUS]:
		var op_token: Token = _advance()
		var right: Expr = _unary()
		
		if not right:
			return null
		
		return Expr.Unary.new(op_token, right)
	
	return _call()


func _exponent() -> Expr:
	if _peek().token_type == Token.EXPONENT:
		interpreter.error_handler.error(_peek().line_num, "Binary operator missing left operand")
		_advance()
		_exponent()
		return null
	
	var expr: Expr = _unary()
	
	if not expr:
		return null
	
	while _peek().token_type == Token.EXPONENT:
		var op_token: Token = _advance()
		var right: Expr = _unary()
		
		if not right:
			return null
		
		expr = Expr.Binary.new(expr, op_token, right)
	
	return expr


func _factor() -> Expr:
	if _peek().token_type in [Token.STAR, Token.SLASH, Token.PERCENT]:
		interpreter.error_handler.error(_peek().line_num, "Binary operator missing left operand")
		_advance()
		_factor()
		return null
	
	var expr: Expr = _exponent()
	
	if not expr:
		return null
	
	while _peek().token_type in [Token.STAR, Token.SLASH, Token.PERCENT]:
		var op_token: Token = _advance()
		var right: Expr = _exponent()
		
		if not right:
			return null
		
		expr = Expr.Binary.new(expr, op_token, right)
	
	return expr


func _term() -> Expr:
	if _peek().token_type == Token.PLUS:
		interpreter.error_handler.error(_peek().line_num, "Binary operator missing left operand")
		_advance()
		_term()
		return null
	
	var expr: Expr = _factor()
	
	if not expr:
		return null
	
	while _peek().token_type in [Token.PLUS, Token.MINUS]:
		var op_token: Token = _advance()
		var right: Expr = _factor()
		
		if not right:
			return null
		
		expr = Expr.Binary.new(expr, op_token, right)
	
	return expr


func _bitwise() -> Expr:
	var bit_ops: Array[int] = [
		Token.BIT_AND, 
		Token.BIT_OR, 
		Token.BIT_XOR, 
		Token.LEFT_SHIFT, 
		Token.RIGHT_SHIFT,
	]
	
	if _peek().token_type in bit_ops:
		interpreter.error_handler.error(_peek().line_num, "Binary operator missing left operand")
		_advance()
		_bitwise()
		return null
	
	var expr: Expr = _term()
	
	if not expr:
		return null
	
	while _peek().token_type in bit_ops:
		var op_token: Token = _advance()
		var right: Expr = _term()
		
		if not right:
			return null
		
		expr = Expr.Binary.new(expr, op_token, right)
	
	return expr


func _conversion() -> Expr:
	if _peek().token_type == Token.AS:
		interpreter.error_handler.error(_peek().line_num, "Binary operator missing left operand")
		_advance()
		_conversion()
		return null
	
	var expr: Expr = _bitwise()
	
	if not expr:
		return null
	
	while _peek().token_type == Token.AS:
		var as_line: int = _advance().line_num
		
		var conversion_type: String
		
		if _peek().token_type == Token.DATA_TYPE:
			conversion_type = _advance().lexeme
		else:
			interpreter.error_handler.error(_peek().line_num, "Type expected")
			return null
		
		expr = Expr.Conversion.new(expr, Typer.data_types[conversion_type], as_line)
	
	return expr


func _comp() -> Expr:
	var comp_ops: Array[int] = [
		Token.COMP_EQUAL, 
		Token.NOT_EQUAL, 
		Token.MORE, 
		Token.MORE_EQUAL, 
		Token.LESS,
		Token.LESS_EQUAL,
	]
	
	if _peek().token_type in comp_ops:
		interpreter.error_handler.error(_peek().line_num, "Binary operator missing left operand")
		_advance()
		_comp()
		return null
	
	var expr: Expr = _conversion()
	
	if not expr:
		return null
	
	while _peek().token_type in comp_ops:
		var op_token: Token = _advance()
		var right: Expr = _conversion()
		
		if not right:
			return null
		
		expr = Expr.Binary.new(expr, op_token, right)
	
	return expr


func _negated() -> Expr:
	if _peek().token_type == Token.NOT:
		var op_token: Token = _advance()
		var right: Expr = _negated()
		
		if not right:
			return null
		
		return Expr.Unary.new(op_token, right)
	
	return _comp()


func _bin_logic() -> Expr:
	var bin_logic_ops: Array[int] = [
		Token.AND, 
		Token.OR, 
		Token.XOR, 
		Token.NAND, 
		Token.NOR,
		Token.XNOR,
	]
	
	if _peek().token_type in bin_logic_ops:
		interpreter.error_handler.error(_peek().line_num, "Binary operator missing left operand")
		_advance()
		_bin_logic()
		return null
	
	var expr: Expr = _negated()
	
	if not expr:
		return null
	
	while _peek().token_type in bin_logic_ops:
		var op_token: Token = _advance()
		var right: Expr = _negated()
		
		if not right:
			return null
		
		expr = Expr.Binary.new(expr, op_token, right)
	
	return expr


func _ternary() -> Expr:
	if _peek().token_type == Token.EXPONENT:
		interpreter.error_handler.error(_peek().line_num, "Binary operator missing left operand")
		_advance()
		_ternary()
		return null
	
	var true_expr: Expr = _bin_logic()
	
	if not true_expr:
		return null
	
	if _peek().token_type == Token.IF:
		var line_num: int = _advance().line_num
		var cond: Expr = _bin_logic()
		
		if not cond:
			return null
		
		if _peek().token_type == Token.ELSE:
			_advance()
			var false_expr: Expr = _ternary()
			
			if not false_expr:
				return null
			
			return Expr.Ternary.new(true_expr, cond, false_expr, line_num)
		else:
			interpreter.error_handler.error(_peek().line_num, "Incomplete ternary expression")
			return null
	
	return true_expr


func _assignment() -> Expr:
	var expr: Expr = _ternary()
	
	var assignment_ops: Array[int] = [
		Token.SET_EQUAL,
		Token.BIT_AND_EQUAL,
		Token.BIT_OR_EQUAL,
		Token.BIT_XOR_EQUAL,
		Token.LEFT_SHIFT_EQUAL,
		Token.RIGHT_SHIFT_EQUAL,
		Token.PLUS_EQUAL,
		Token.MINUS_EQUAL,
		Token.STAR_EQUAL,
		Token.SLASH_EQUAL,
		Token.PERCENT_EQUAL,
		Token.EXPONENT_EQUAL,
	]
	
	if _peek().token_type in assignment_ops:
		var op_token: Token = _advance()
		var value: Expr = _assignment()
		
		if expr is Expr.Variable:
			var name_token: Token = expr.name_token
			return Expr.Assignment.new(name_token, op_token, value)
		
		interpreter.error_handler.error(op_token.line_num, "Invalid assignment target")
	
	return expr


func _expression() -> Expr:
	return _assignment()


func _expression_statement() -> Statement:
	# Get line_num from first token
	var line_num: int = _peek().line_num
	
	var expr: Expr = _expression()
	
	if not expr:
		return null
	
	if _peek().token_type == Token.NEW_LINE:
		# Consume the new line
		_advance()
	elif _peek().token_type == Token.EOF:
		# We are at the end of the file. This is also the end of the line
		pass
	else:
		interpreter.error_handler.error(line_num, "Expected new line. Got %s" % _peek().lexeme)
		return null
	
	return Statement.ExprStmt.new(line_num, expr)


func _declaration_statement() -> Statement:
	# Use type token for starting line and data type
	var type_token: Token = _advance()
	var line_num: int = type_token.line_num
	var data_type: WolfType = Typer.data_types[type_token.lexeme]
	
	if not data_type.inherits(Typer.data_types["value"]):
		var msg: String = "Can not declare variable of type %s" % data_type
		interpreter.error_handler.error(line_num, msg)
		return null
	
	var name_token: Token
	if _peek().token_type == Token.IDENTIFIER:
		name_token = _advance()
	else:
		var msg: String = "Variable name expected after type for variable declaration"
		interpreter.error_handler.error(line_num, msg)
		return null
	
	if name_token.lexeme in current_env.types:
		var msg: String = "Variable '%s' is already defined" % name_token.lexeme
		interpreter.error_handler.error(line_num, msg)
		return null
	elif current_env.var_has_type(name_token.lexeme):
		var msg: String = "Variable '%s' shadows external variable" % name_token.lexeme
		interpreter.error_handler.warn(line_num, msg)
	
	var initializer: Expr = null
	
	if _peek().token_type == Token.SET_EQUAL:
		# Consume equal sign
		_advance()
		
		initializer = _expression()
		
		if not initializer:
			return null
	
	if _peek().token_type == Token.NEW_LINE:
		# Consume the new line
		_advance()
	elif _peek().token_type == Token.EOF:
		# We are at the end of the file. This is also the end of the line
		pass
	else:
		interpreter.error_handler.error(line_num, "Only one statement allowed per line")
		return null
	
	current_env.types[name_token.lexeme] = data_type
	
	return Statement.Declaration.new(line_num, data_type, name_token, initializer)


func _block(local_var_types: Dictionary[String, WolfType] = {}) -> Statement.Block:
	# Get line_num from Indent
	var line_num: int = _advance().line_num
	
	var indent_count: int = 1
	
	while _peek().token_type == Token.INDENT:
		_advance()
		indent_count += 1
	
	var new_env: WolfEnvironment = WolfEnvironment.new(current_env)
	current_env = new_env
	
	for local_var_name: String in local_var_types:
		current_env.types[local_var_name] = local_var_types[local_var_name]
	
	var statements: Array[Statement]
	
	while _peek().token_type != Token.OUTDENT and not _is_at_end():
		var statement: Statement = _statement()
		
		if not statement:
			return null
		
		statements.append(statement)
	
	for i in range(indent_count):
		if _is_at_end():
			break
		elif _peek().token_type == Token.OUTDENT:
			_advance()
		else:
			interpreter.error_handler.error(_peek().line_num, "Insuficient outdentation")
			return null
	
	current_env = new_env.parent_environment
	
	return Statement.Block.new(line_num, statements, new_env)


func _if() -> Statement:
	# Get line_num from if
	var line_num: int = _advance().line_num
	
	var cond: Expr = _expression()
	
	if not cond:
		return null
	
	# Consume colon
	if _peek().token_type == Token.COLON:
		_advance()
	else:
		interpreter.error_handler.error(line_num, "':' expected after if condition")
		return null
	
	# Consume new line
	if _peek().token_type == Token.NEW_LINE:
		_advance()
	else:
		interpreter.error_handler.error(line_num, "New line expected after if")
		return null
	
	var if_block: Statement.Block
	
	# Get indented block
	if _peek().token_type == Token.INDENT:
		if_block = _block()
		
		if not if_block:
			return null
	else:
		interpreter.error_handler.error(line_num, "Indented block expected after if")
		return null
	
	var elif_lines: Array[int] = []
	var elif_conds: Array[Expr] = []
	var elif_blocks: Array[Statement.Block] = []
	while _peek().token_type == Token.ELIF:
		# Get line_num from elif
		var new_line_num: int = _advance().line_num
		elif_lines.append(new_line_num)
		
		var new_cond: Expr = _expression()
		
		if not cond:
			return null
		
		elif_conds.append(new_cond)
		
		# Consume colon
		if _peek().token_type == Token.COLON:
			_advance()
		else:
			interpreter.error_handler.error(line_num, "':' expected after elif condition")
			return null
		
		# Consume new line
		if _peek().token_type == Token.NEW_LINE:
			_advance()
		else:
			interpreter.error_handler.error(line_num, "New line expected after elif")
			return null
		
		var elif_block: Statement.Block
		
		# Get indented block
		if _peek().token_type == Token.INDENT:
			elif_block = _block()
			
			if not elif_block:
				return null
			
			elif_blocks.append(elif_block)
		else:
			interpreter.error_handler.error(line_num, "Indented block expected after elif")
			return null
	
	var else_line: int = 0
	var else_block: Statement.Block = null
	if _peek().token_type == Token.ELSE:
		# Get line_num from else
		else_line = _advance().line_num
		
		# Consume colon
		if _peek().token_type == Token.COLON:
			_advance()
		else:
			interpreter.error_handler.error(line_num, "':' expected after else")
			return null
		
		# Consume new line
		if _peek().token_type == Token.NEW_LINE:
			_advance()
		else:
			interpreter.error_handler.error(line_num, "New line expected after else")
			return null
		
		# Get indented block
		if _peek().token_type == Token.INDENT:
			else_block = _block()
			
			if not else_block:
				return null
		else:
			interpreter.error_handler.error(line_num, "Indented block expected after else")
			return null
	
	return Statement.If.new(line_num, cond, if_block, elif_conds, elif_blocks, elif_lines, 
			else_block, else_line)


func _while() -> Statement:
	# Get line_num from while
	var line_num: int = _advance().line_num
	
	var cond: Expr = _expression()
	
	if not cond:
		return null
	
	# Consume colon
	if _peek().token_type == Token.COLON:
		_advance()
	else:
		interpreter.error_handler.error(line_num, "':' expected after while condition")
		return null
	
	# Consume new line
	if _peek().token_type == Token.NEW_LINE:
		_advance()
	else:
		interpreter.error_handler.error(line_num, "New line expected after while")
		return null
	
	var block: Statement.Block
	
	# Get indented block
	if _peek().token_type == Token.INDENT:
		block = _block()
		
		if not block:
			return null
	else:
		interpreter.error_handler.error(line_num, "Indented block expected after while")
		return null
	
	return Statement.While.new(line_num, cond, block)


func _for() -> Statement:
	# Get line_num from for
	var line_num: int = _advance().line_num
	
	var var_type: WolfType
	
	if _peek().token_type == Token.DATA_TYPE:
		var_type = Typer.data_types[_advance().lexeme]
	else:
		interpreter.error_handler.error(line_num, "Variable type expected after for")
		return null
	
	var var_name: String
	
	if _peek().token_type == Token.IDENTIFIER:
		var_name = _advance().lexeme
	else:
		interpreter.error_handler.error(line_num, "Variable name expected after its type")
		return null
	
	# Consume in
	if _peek().token_type == Token.IN:
		_advance()
	else:
		interpreter.error_handler.error(line_num, "'in' expected after for variable")
		return null
	
	# Consume range
	if _peek().token_type == Token.RANGE:
		_advance()
	else:
		interpreter.error_handler.error(line_num, "'range' expected after 'in'")
		return null
	
	# Consume (
	if _peek().token_type == Token.OPEN_PAREN:
		_advance()
	else:
		interpreter.error_handler.error(line_num, "'(' expected after 'range'")
		return null
	
	# End is required but start and step default to 0 and 1 respectively
	var start: Expr = Expr.Literal.new(Token.new(Token.LITERAL, "0", WolfInt.new(0), line_num))
	var end: Expr
	var step: Expr = Expr.Literal.new(Token.new(Token.LITERAL, "1", WolfInt.new(1), line_num))
	
	end = _expression()
	
	if not end:
		return null
	
	if _peek().token_type == Token.COMMA:
		_advance()
		
		start = end
		
		end = _expression()
		
		if not end:
			return null
		
		if _peek().token_type == Token.COMMA:
			_advance()
			
			step = _expression()
			
			if not step:
				return null
	
	# Consume )
	if _peek().token_type == Token.CLOSE_PAREN:
		_advance()
	else:
		interpreter.error_handler.error(line_num, "')' expected after range params")
		return null
	
	# Consume colon
	if _peek().token_type == Token.COLON:
		_advance()
	else:
		interpreter.error_handler.error(line_num, "':' expected after for")
		return null
	
	# Consume new line
	if _peek().token_type == Token.NEW_LINE:
		_advance()
	else:
		interpreter.error_handler.error(line_num, "New line expected after for")
		return null
	
	var block: Statement.Block
	
	# Get indented block
	if _peek().token_type == Token.INDENT:
		block = _block({var_name: var_type})
		
		if not block:
			return null
	else:
		interpreter.error_handler.error(line_num, "Indented block expected after for")
		return null
	
	return Statement.ForRange.new(line_num, var_type, var_name, start, end, step, block)


func _statement() -> Statement:
	var statement: Statement
	
	match _peek().token_type:
		Token.NEW_LINE:
			return Statement.Empty.new(_advance().line_num)
		Token.DATA_TYPE:
			statement = _declaration_statement()
		Token.IF:
			statement = _if()
		Token.WHILE:
			statement = _while()
		Token.FOR:
			statement = _for()
		_:
			statement = _expression_statement()
	
	if not statement:
		# If we have a problem, just eat the rest of the line
		while _peek().token_type not in [Token.NEW_LINE, Token.EOF]:
			_advance()
		
		_advance()
	
	return statement


func parse() -> Array[Statement]:
	current_env = interpreter.environment
	
	var statements: Array[Statement] = []
	while not _is_at_end():
		var next_statement: Statement = _statement()
		if next_statement:
			statements.append(next_statement)
	
	return statements
