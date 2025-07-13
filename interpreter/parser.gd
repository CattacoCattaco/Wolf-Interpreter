class_name Parser
extends RefCounted

var tokens: Array[Token]
var current: int = 0

## A reference to the interpreter which created this
var interpreter: Interpreter


func _init(p_tokens: Array[Token]) -> void:
	tokens = p_tokens


func _is_at_end() -> bool:
	return current >= len(tokens) - 1


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
	
	if _peek().token_type == Token.OPEN_PAREN:
		var expr: Expr = _expression()
		
		if _peek().token_type == Token.CLOSE_PAREN:
			if not expr:
				return null
			
			_advance()
			return expr
		else:
			interpreter.error_handler.error(_peek().line_num, "Unclosed parentheses")
			return null
	
	interpreter.error_handler.error(_peek().line_num, "Expression expected")
	
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
	
	var expr: Expr = _bitwise()
	
	if not expr:
		return null
	
	while _peek().token_type in comp_ops:
		var op_token: Token = _advance()
		var right: Expr = _bitwise()
		
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
		_advance()
		var cond: Expr = _bin_logic()
		
		if not cond:
			return null
		
		if _peek().token_type == Token.ELSE:
			_advance()
			var false_expr: Expr = _ternary()
			
			if not false_expr:
				return null
			
			return Expr.Ternary.new(true_expr, cond, false_expr)
		else:
			interpreter.error_handler.error(_peek().line_num, "Incomplete ternary expression")
			return null
	
	return true_expr


func _expression() -> Expr:
	return _ternary()


func parse() -> Expr:
	var expr: Expr = _expression()
	
	if not expr:
		return null
	
	return expr
