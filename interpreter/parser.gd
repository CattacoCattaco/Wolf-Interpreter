class_name Parser
extends RefCounted

var tokens: Array[Token]
var current: int = 0

## A reference to the interpreter which created this
var interpreter: Interpreter


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
		if _peek().lexeme not in interpreter.environment.types:
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


func _type(required: bool = true) -> Token:
	if _peek().token_type == Token.IDENTIFIER and _peek().lexeme in Typer.DATA_TYPES:
		return _advance()
	else:
		if required:
			interpreter.error_handler.error(_peek().line_num, "Type expected")
		
		return null


func _unary() -> Expr:
	if _peek().token_type in [Token.BIT_NOT, Token.MINUS]:
		var op_token: Token = _advance()
		var right: Expr = _unary()
		
		if not right:
			return null
		
		return Expr.Unary.new(op_token, right)
	
	return _primary()


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
		
		expr = Expr.Conversion.new(expr, conversion_type, as_line)
	
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
		var value: Expr = _ternary()
		
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


func _print_statement() -> Statement:
	# Consume print keyword and opening paren while getting line num from print
	var line_num: int = _advance().line_num
	if _peek().token_type == Token.OPEN_PAREN:
		_advance()
	else:
		interpreter.error_handler.error(line_num, "'(' expected after print")
		return null
	
	var printed_expr: Expr = _expression()
	
	if not printed_expr:
		return null
	
	# Consume closing paren
	if _peek().token_type == Token.CLOSE_PAREN:
		_advance()
	else:
		interpreter.error_handler.error(line_num, "')' expected after printed expression")
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
	
	return Statement.Print.new(line_num, printed_expr)


func _declaration_statement() -> Statement:
	# Use type token for starting line and data type
	var type_token: Token = _advance()
	var line_num: int = type_token.line_num
	var data_type: String = type_token.lexeme
	
	if type_token.lexeme in ["null", "mixed"]:
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
	
	if name_token.lexeme in interpreter.environment.types:
		var msg: String = "Variable '%s' is already defined" % name_token.lexeme
		interpreter.error_handler.error(line_num, msg)
	
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
	
	interpreter.environment.types[name_token.lexeme] = data_type
	
	return Statement.Declaration.new(line_num, data_type, name_token, initializer)


func _statement() -> Statement:
	var statement: Statement
	
	match _peek().token_type:
		Token.PRINT:
			statement = _print_statement()
		Token.DATA_TYPE:
			statement = _declaration_statement()
		_:
			statement = _expression_statement()
	
	if not statement:
		# If we have a problem, just eat the rest of the line
		while _peek().token_type not in [Token.NEW_LINE, Token.EOF]:
			_advance()
		
		_advance()
	
	return statement


func parse() -> Array[Statement]:
	var statements: Array[Statement] = []
	while not _is_at_end():
		var next_statement = _statement()
		if next_statement:
			statements.append(next_statement)
	
	return statements
