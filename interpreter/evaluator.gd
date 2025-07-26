class_name Evaluator
extends RefCounted

## A reference to the interpreter which created this
var interpreter: Interpreter

var current_env: WolfEnvironment

var _stopped: bool = false


func stop() -> void:
	_stopped = true


func start() -> void:
	_stopped = false


func evaluate_statements(statements: Array[Statement]) -> void:
	if _stopped:
		return
	
	if not current_env:
		current_env = interpreter.environment
	
	for statement in statements:
		await evaluate_statement(statement)


func evaluate_statement(statement: Statement) -> void:
	if _stopped:
		return
	
	if statement is Statement.Declaration:
		await evaluate_declaration_statement(statement)
	elif statement is Statement.Block:
		await evaluate_block_statement(statement)
	elif statement is Statement.If:
		await evaluate_if_statement(statement)
	elif statement is Statement.While:
		await evaluate_while_statement(statement)
	elif statement is Statement.ForRange:
		await evaluate_for_range_statement(statement)
	elif statement is Statement.ExprStmt:
		await evaluate_expr_statement(statement)


func evaluate_expr_statement(statement: Statement.ExprStmt) -> void:
	if _stopped:
		return
	
	await evaluate_expr(statement.expr)
	return


func evaluate_declaration_statement(statement: Statement.Declaration) -> void:
	if _stopped:
		return
	
	if statement.initializer:
		var init_value: Variant = await evaluate_expr(statement.initializer)
		current_env.values[statement.name.lexeme] = init_value
	else:
		match statement.data_type.base_type_name:
			"int":
				current_env.values[statement.name.lexeme] = WolfInt.new(0)
			"char":
				current_env.values[statement.name.lexeme] = WolfChar.new(0)
			"float":
				current_env.values[statement.name.lexeme] = WolfFloat.new(0.0)
			"string":
				current_env.values[statement.name.lexeme] = WolfString.new("")
			"bool":
				current_env.values[statement.name.lexeme] = WolfBool.new(false)
	
	return


func evaluate_block_statement(statement: Statement.Block) -> void:
	if _stopped:
		return
	
	current_env = statement.environment
	await evaluate_statements(statement.statements)
	current_env = current_env.parent_environment
	return


func evaluate_if_statement(statement: Statement.If) -> void:
	if _stopped:
		return
	
	if (await evaluate_expr(statement.condition)).value:
		await evaluate_block_statement(statement.block)
		return
	
	for i in len(statement.elif_blocks):
		if (await evaluate_expr(statement.elif_conds[i])).value:
			await evaluate_block_statement(statement.elif_blocks[i])
			return
	
	if statement.else_block:
		await evaluate_block_statement(statement.else_block)
	return


func evaluate_while_statement(statement: Statement.While) -> void:
	if _stopped:
		return
	
	while not _stopped and (await evaluate_expr(statement.condition)).value:
		if _stopped:
			return
		
		statement.block.environment.values = {}
		await evaluate_block_statement(statement.block)
	
	return


func evaluate_for_range_statement(statement: Statement.ForRange) -> void:
	if _stopped:
		return
	
	var start_amount: int = (await evaluate_expr(statement.start)).value
	var end_amount: int = (await evaluate_expr(statement.end)).value
	var step_amount: int = (await evaluate_expr(statement.step)).value
	
	for i: int in range(start_amount, end_amount, step_amount):
		statement.block.environment.values = {}
		
		var i_literal := Expr.Literal.new(Token.new(Token.LITERAL, "i", WolfInt.new(i)))
		var i_conversion := Expr.Conversion.new(i_literal, statement.var_type, statement.line_start)
		var converted_i: Variant = await eval_conversion(i_conversion)
		statement.block.environment.values[statement.var_name] = converted_i
		
		await evaluate_block_statement(statement.block)
	
	return


func evaluate_expr(expr: Expr) -> WolfObject:
	if _stopped:
		return null
	
	if expr is Expr.Literal:
		return eval_literal(expr)
	elif expr is Expr.Variable:
		return eval_variable(expr)
	elif expr is Expr.Grouping:
		return await eval_group(expr)
	elif expr is Expr.Call:
		return await eval_call(expr)
	elif expr is Expr.Conversion:
		return await eval_conversion(expr)
	elif expr is Expr.Unary:
		return await eval_unary(expr)
	elif expr is Expr.Binary:
		return await eval_binary(expr)
	elif expr is Expr.Ternary:
		return await eval_ternary(expr)
	elif expr is Expr.Assignment:
		return await eval_assignment(expr)
	
	return null


func eval_literal(expr: Expr.Literal) -> WolfObject:
	if _stopped:
		return null
	
	return expr.literal_token.literal_value


func eval_variable(expr: Expr.Variable) -> WolfObject:
	if _stopped:
		return null
	
	return current_env.get_value(expr.name_token.lexeme)


func eval_group(expr: Expr.Grouping) -> WolfObject:
	if _stopped:
		return null
	
	return await evaluate_expr(expr.grouped_expr)


func eval_call(expr: Expr.Call) -> WolfObject:
	if _stopped:
		return null
	
	var args: Array[WolfObject] = []
	var arg_types: Array[WolfType] = []
	
	for arg in expr.args:
		var value: WolfObject = await evaluate_expr(arg)
		args.append(value)
		arg_types.append(value._get_type())
	
	var ret_type: WolfType
	
	if not expr.ret_type:
		var typer := Typer.new()
		typer.current_env = current_env
		typer.interpreter = interpreter
		
		ret_type = typer.get_call_type(expr)
		
		if interpreter.error_handler.errors:
			return null
	else:
		ret_type = expr.ret_type
	
	var definition: CallableDefenition = expr.callable._def_to_use(arg_types)
	
	var result: WolfObject = await expr.callable._call(args, definition, expr.close_paren.line_num)
	
	return result


func eval_conversion(expr: Expr.Conversion) -> WolfObject:
	if _stopped:
		return null
	
	var unconverted_result: WolfObject = await evaluate_expr(expr.converted_expr)
	
	var types: Array[WolfType] = [unconverted_result._get_type(), expr.new_type]
	
	# Already the right type
	if types[0] == types[1]:
		return unconverted_result
	
	match types[1].base_type_name:
		"string":
			return WolfString.new(str(unconverted_result))
		"int":
			if types[0] == Typer.data_types["float"]:
				return WolfInt.new(unconverted_result.value)
			elif types[0] == Typer.data_types["char"]:
				return WolfInt.new(unconverted_result.value)
			elif types[0] == Typer.data_types["bool"]:
				return WolfInt.new(unconverted_result.value as int)
		"char":
			if types[0] == Typer.data_types["float"]:
				return WolfChar.new(unconverted_result.value)
			elif types[0] == Typer.data_types["int"]:
				return WolfChar.new(unconverted_result.value)
			elif types[0] == Typer.data_types["bool"]:
				return WolfChar.new(unconverted_result.value as int)
		"float":
			if types[0] == Typer.data_types["int"]:
				return WolfFloat.new(unconverted_result.value)
			elif types[0] == Typer.data_types["char"]:
				return WolfFloat.new(unconverted_result.value)
			elif types[0] == Typer.data_types["bool"]:
				return WolfFloat.new(unconverted_result.value as float)
		"bool":
			return WolfBool.new(is_truthy(unconverted_result))
	
	var msg: String = "Invalid type conversion from %s to %s" % types
	interpreter.error_handler.error(expr.line, msg)
	return null


func eval_unary(expr: Expr.Unary) -> WolfObject:
	if _stopped:
		return null
	
	match expr.op_token.token_type:
		Token.BIT_NOT:
			return await eval_bit_not(expr)
		Token.NOT:
			return await eval_not(expr)
		Token.MINUS:
			return await eval_unary_minus(expr)
	
	return null


func eval_bit_not(expr: Expr.Unary) -> WolfObject:
	if _stopped:
		return null
	
	var value_to_negate: WolfObject = await evaluate_expr(expr.right)
	
	if value_to_negate._get_type() == Typer.data_types["char"]:
		return WolfChar.new(~value_to_negate.value)
	
	return WolfInt.new(~value_to_negate.value)


func eval_not(expr: Expr.Unary) -> WolfObject:
	if _stopped:
		return null
	
	var value_to_negate: WolfObject = await evaluate_expr(expr.right)
	return WolfBool.new(not value_to_negate.value)


func eval_unary_minus(expr: Expr.Unary) -> WolfObject:
	if _stopped:
		return null
	
	var value_to_invert: WolfObject = await evaluate_expr(expr.right)
	
	match value_to_invert._get_type().base_type_name:
		"float":
			return WolfFloat.new(-value_to_invert.value)
		"int":
			return WolfInt.new(-value_to_invert.value)
	
	return null


func eval_binary(expr: Expr.Binary) -> WolfObject:
	if _stopped:
		return null
	
	match expr.op_token.token_type:
		Token.AND:
			return await eval_and(expr)
		Token.OR:
			return await eval_or(expr)
		Token.XOR:
			return await eval_xor(expr)
		Token.NAND:
			return await eval_nand(expr)
		Token.NOR:
			return await eval_nor(expr)
		Token.XNOR:
			return await eval_xnor(expr)
		Token.BIT_AND:
			return await eval_bit_and(expr)
		Token.BIT_OR:
			return await eval_bit_or(expr)
		Token.BIT_XOR:
			return await eval_bit_xor(expr)
		Token.LEFT_SHIFT:
			return await eval_left_shift(expr)
		Token.RIGHT_SHIFT:
			return await eval_right_shift(expr)
		Token.PLUS:
			return await eval_plus(expr)
		Token.MINUS:
			return await eval_binary_minus(expr)
		Token.STAR:
			return await eval_multiply(expr)
		Token.SLASH:
			return await eval_divide(expr)
		Token.PERCENT:
			return await eval_modulo(expr)
		Token.MORE:
			return await eval_more(expr)
		Token.EXPONENT:
			return await eval_exponent(expr)
		Token.MORE_EQUAL:
			return await eval_more_equal(expr)
		Token.LESS:
			return await eval_less(expr)
		Token.LESS_EQUAL:
			return await eval_less_equal(expr)
		Token.COMP_EQUAL:
			return await eval_comp_equal(expr)
		Token.NOT_EQUAL:
			return await eval_not_equal(expr)
	
	return null


func eval_and(expr: Expr.Binary) -> WolfObject:
	if _stopped:
		return null
	
	var left_value: WolfObject = await evaluate_expr(expr.left)
	var right_value: WolfObject = await evaluate_expr(expr.right)
	
	if is_truthy(left_value):
		return right_value
	else:
		return left_value


func eval_or(expr: Expr.Binary) -> WolfObject:
	if _stopped:
		return null
	
	var left_value: WolfObject = await evaluate_expr(expr.left)
	var right_value: WolfObject = await evaluate_expr(expr.right)
	
	if is_truthy(left_value):
		return left_value
	else:
		return right_value


func eval_xor(expr: Expr.Binary) -> WolfObject:
	if _stopped:
		return null
	
	var left_value: WolfObject = await evaluate_expr(expr.left)
	var right_value: WolfObject = await evaluate_expr(expr.right)
	
	var left: bool = left_value.value
	var right: bool = right_value.value
	
	var at_least_one: bool = left or right
	var both: bool = left and right
	
	return WolfBool.new(at_least_one and not both)


func eval_nand(expr: Expr.Binary) -> WolfObject:
	if _stopped:
		return null
	
	var left_value: WolfObject = await evaluate_expr(expr.left)
	var right_value: WolfObject = await evaluate_expr(expr.right)
	
	var left: bool = left_value.value
	var right: bool = right_value.value
	
	return WolfBool.new(not (left and right))


func eval_nor(expr: Expr.Binary) -> WolfObject:
	if _stopped:
		return null
	
	var left_value: WolfObject = await evaluate_expr(expr.left)
	var right_value: WolfObject = await evaluate_expr(expr.right)
	
	var left: bool = left_value.value
	var right: bool = right_value.value
	
	return WolfBool.new(not (left or right))


func eval_xnor(expr: Expr.Binary) -> WolfObject:
	if _stopped:
		return null
	
	var left_value: WolfObject = await evaluate_expr(expr.left)
	var right_value: WolfObject = await evaluate_expr(expr.right)
	
	var left: bool = left_value.value
	var right: bool = right_value.value
	
	var at_least_one: bool = left or right
	var both: bool = left and right
	
	return WolfBool.new(both or not at_least_one)


func eval_bit_and(expr: Expr.Binary) -> WolfObject:
	if _stopped:
		return null
	
	var left_value: WolfObject = await evaluate_expr(expr.left)
	var right_value: WolfObject = await evaluate_expr(expr.right)
	
	var result: WolfObject
	match expr.left.ret_type.base_type_name:
		"char":
			result = WolfChar.new(left_value.value & right_value.value)
		"int":
			result = WolfInt.new(left_value.value & right_value.value)
	
	return result


func eval_bit_or(expr: Expr.Binary) -> WolfObject:
	if _stopped:
		return null
	
	var left_value: WolfObject = await evaluate_expr(expr.left)
	var right_value: WolfObject = await evaluate_expr(expr.right)
	
	var result: WolfObject
	match expr.left.ret_type.base_type_name:
		"char":
			result = WolfChar.new(left_value.value | right_value.value)
		"int":
			result = WolfInt.new(left_value.value | right_value.value)
	
	return result


func eval_bit_xor(expr: Expr.Binary) -> WolfObject:
	if _stopped:
		return null
	
	var left_value: WolfObject = await evaluate_expr(expr.left)
	var right_value: WolfObject = await evaluate_expr(expr.right)
	
	var result: WolfObject
	match expr.left.ret_type.base_type_name:
		"char":
			result = WolfChar.new(left_value.value ^ right_value.value)
		"int":
			result = WolfInt.new(left_value.value ^ right_value.value)
	
	return result


func eval_left_shift(expr: Expr.Binary) -> WolfObject:
	if _stopped:
		return null
	
	var left_value: WolfObject = await evaluate_expr(expr.left)
	var right_value: WolfObject = await evaluate_expr(expr.right)
	
	var result: WolfObject
	match expr.left.ret_type.base_type_name:
		"char":
			result = WolfChar.new(left_value.value << right_value.value)
		"int":
			result = WolfInt.new(left_value.value << right_value.value)
	
	return result


func eval_right_shift(expr: Expr.Binary) -> WolfObject:
	if _stopped:
		return null
	
	var left_value: WolfObject = await evaluate_expr(expr.left)
	var right_value: WolfObject = await evaluate_expr(expr.right)
	
	var result: WolfObject
	match expr.left.ret_type.base_type_name:
		"char":
			result = WolfChar.new(left_value.value >> right_value.value)
		"int":
			result = WolfInt.new(left_value.value >> right_value.value)
	
	return result


func eval_plus(expr: Expr.Binary) -> WolfObject:
	if _stopped:
		return null
	
	var left_value: WolfObject = await evaluate_expr(expr.left)
	var right_value: WolfObject = await evaluate_expr(expr.right)
	
	var result: WolfObject
	match expr.left.ret_type.base_type_name:
		"char":
			result = WolfChar.new(left_value.value + right_value.value)
		"int":
			result = WolfInt.new(left_value.value + right_value.value)
		"float":
			result = WolfFloat.new(left_value.value + right_value.value)
		"string":
			result = WolfString.new(left_value.value + right_value.value)
	
	return result


func eval_binary_minus(expr: Expr.Binary) -> WolfObject:
	if _stopped:
		return null
	
	var left_value: WolfObject = await evaluate_expr(expr.left)
	var right_value: WolfObject = await evaluate_expr(expr.right)
	
	var result: WolfObject
	match expr.left.ret_type.base_type_name:
		"char":
			result = WolfChar.new(left_value.value - right_value.value)
		"int":
			result = WolfInt.new(left_value.value - right_value.value)
		"float":
			result = WolfFloat.new(left_value.value - right_value.value)
	
	return result


func eval_multiply(expr: Expr.Binary) -> WolfObject:
	if _stopped:
		return null
	
	var left_value: WolfObject = await evaluate_expr(expr.left)
	var right_value: WolfObject = await evaluate_expr(expr.right)
	
	var result: WolfObject
	match expr.left.ret_type.base_type_name:
		"char":
			result = WolfChar.new(left_value.value * right_value.value)
		"int":
			result = WolfInt.new(left_value.value * right_value.value)
		"float":
			result = WolfFloat.new(left_value.value * right_value.value)
	
	return result


func eval_divide(expr: Expr.Binary) -> WolfObject:
	if _stopped:
		return null
	
	var left_value: WolfObject = await evaluate_expr(expr.left)
	var right_value: WolfObject = await evaluate_expr(expr.right)
	
	var result: WolfObject
	match expr.left.ret_type.base_type_name:
		"char":
			result = WolfChar.new(left_value.value / right_value.value)
		"int":
			result = WolfInt.new(left_value.value / right_value.value)
		"float":
			result = WolfFloat.new(left_value.value / right_value.value)
	
	return result


func eval_modulo(expr: Expr.Binary) -> WolfObject:
	if _stopped:
		return null
	
	var left_value: WolfObject = await evaluate_expr(expr.left)
	var right_value: WolfObject = await evaluate_expr(expr.right)
	
	var result: WolfObject
	match expr.left.ret_type.base_type_name:
		"char":
			result = WolfChar.new(posmod(left_value.value, right_value.value))
		"int":
			result = WolfInt.new(posmod(left_value.value, right_value.value))
		"float":
			result = WolfFloat.new(fposmod(left_value.value, right_value.value))
	
	return result


func eval_exponent(expr: Expr.Binary) -> WolfObject:
	if _stopped:
		return null
	
	var left_value: WolfObject = await evaluate_expr(expr.left)
	var right_value: WolfObject = await evaluate_expr(expr.right)
	
	var result: WolfObject
	match expr.left.ret_type.base_type_name:
		"char":
			result = WolfChar.new(left_value.value ** right_value.value)
		"int":
			result = WolfInt.new(left_value.value ** right_value.value)
		"float":
			result = WolfFloat.new(pow(left_value.value, right_value.value))
	
	return result


func eval_more(expr: Expr.Binary) -> WolfObject:
	if _stopped:
		return null
	
	var left_value: WolfObject = await evaluate_expr(expr.left)
	var right_value: WolfObject = await evaluate_expr(expr.right)
	
	var result: WolfBool
	match expr.left.ret_type.base_type_name:
		"char":
			result = WolfBool.new(left_value.value > right_value.value)
		"int":
			result = WolfBool.new(left_value.value > right_value.value)
		"float":
			result = WolfBool.new(left_value.value > right_value.value)
	
	return result


func eval_more_equal(expr: Expr.Binary) -> WolfObject:
	if _stopped:
		return null
	
	var left_value: WolfObject = await evaluate_expr(expr.left)
	var right_value: WolfObject = await evaluate_expr(expr.right)
	
	var result: WolfBool
	match expr.left.ret_type.base_type_name:
		"char":
			result = WolfBool.new(left_value.value >= right_value.value)
		"int":
			result = WolfBool.new(left_value.value >= right_value.value)
		"float":
			result = WolfBool.new(left_value.value >= right_value.value)
	
	return result


func eval_less(expr: Expr.Binary) -> WolfObject:
	if _stopped:
		return null
	
	var left_value: WolfObject = await evaluate_expr(expr.left)
	var right_value: WolfObject = await evaluate_expr(expr.right)
	
	var result: WolfBool
	match expr.left.ret_type.base_type_name:
		"char":
			result = WolfBool.new(left_value.value < right_value.value)
		"int":
			result = WolfBool.new(left_value.value < right_value.value)
		"float":
			result = WolfBool.new(left_value.value < right_value.value)
	
	return result


func eval_less_equal(expr: Expr.Binary) -> WolfObject:
	if _stopped:
		return null
	
	var left_value: WolfObject = await evaluate_expr(expr.left)
	var right_value: WolfObject = await evaluate_expr(expr.right)
	
	var result: WolfBool
	match expr.left.ret_type.base_type_name:
		"char":
			result = WolfBool.new(left_value.value <= right_value.value)
		"int":
			result = WolfBool.new(left_value.value <= right_value.value)
		"float":
			result = WolfBool.new(left_value.value <= right_value.value)
	
	return result


func eval_comp_equal(expr: Expr.Binary) -> WolfObject:
	if _stopped:
		return null
	
	var left_value: WolfObject = await evaluate_expr(expr.left)
	var right_value: WolfObject = await evaluate_expr(expr.right)
	
	var result: bool
	match expr.left.ret_type.base_type_name:
		"char":
			result = left_value.value == right_value.value
		"int":
			result = left_value.value == right_value.value
		"float":
			result = left_value.value == right_value.value
		"string":
			result = left_value.value == right_value.value
		"bool":
			result = left_value.value == right_value.value
		"null":
			result = true
	
	return WolfBool.new(result)


func eval_not_equal(expr: Expr.Binary) -> WolfObject:
	if _stopped:
		return null
	
	var left_value: WolfObject = await evaluate_expr(expr.left)
	var right_value: WolfObject = await evaluate_expr(expr.right)
	
	var result: bool
	match expr.left.ret_type.base_type_name:
		"char":
			result = left_value.value.unicode_at(0) != right_value.value.unicode_at(0)
		"int":
			result = left_value.value != right_value.value
		"float":
			result = left_value.value != right_value.value
		"string":
			result = left_value.value != right_value.value
		"bool":
			result = left_value.value != right_value.value
		"null":
			result = false
	
	return WolfBool.new(result)


func eval_ternary(expr: Expr.Ternary) -> WolfObject:
	if _stopped:
		return null
	
	var cond_eval: WolfObject = await evaluate_expr(expr.cond)
	var cond_met: bool = cond_eval.value
	
	var true_value: WolfObject = await evaluate_expr(expr.true_exp)
	var false_value: WolfObject = await evaluate_expr(expr.false_exp)
	
	return true_value if cond_met else false_value


func eval_assignment(expr: Expr.Assignment) -> WolfObject:
	if _stopped:
		return null
	
	var var_type: WolfType = current_env.get_type(expr.name_token.lexeme)
	var value: Variant = await evaluate_expr(expr.value_expr)
	
	match expr.op_token.token_type:
		Token.SET_EQUAL:
			current_env.set_value(expr.name_token.lexeme, value)
		Token.BIT_AND_EQUAL:
			if var_type == Typer.data_types["char"]:
				var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
				var new_value := WolfChar.new(current_value.value & value.value)
				current_env.set_value(expr.name_token.lexeme, new_value)
			else:
				var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
				var new_value := WolfInt.new(current_value.value & value.value)
				current_env.set_value(expr.name_token.lexeme, new_value)
		Token.BIT_OR_EQUAL:
			if var_type == Typer.data_types["char"]:
				var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
				var new_value := WolfChar.new(current_value.value | value.value)
				current_env.set_value(expr.name_token.lexeme, new_value)
			else:
				var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
				var new_value := WolfInt.new(current_value.value | value.value)
				current_env.set_value(expr.name_token.lexeme, new_value)
		Token.BIT_XOR_EQUAL:
			if var_type == Typer.data_types["char"]:
				var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
				var new_value := WolfChar.new(current_value.value ^ value.value)
				current_env.set_value(expr.name_token.lexeme, new_value)
			else:
				var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
				var new_value := WolfInt.new(current_value.value ^ value.value)
				current_env.set_value(expr.name_token.lexeme, new_value)
		Token.LEFT_SHIFT_EQUAL:
			if var_type == Typer.data_types["char"]:
				var current_value := current_env.get_value(expr.name_token.lexeme)
				var new_value := WolfChar.new(current_value.value << value.value)
				current_env.set_value(expr.name_token.lexeme, new_value)
			else:
				var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
				var new_value := WolfInt.new(current_value.value << value.value)
				current_env.set_value(expr.name_token.lexeme, new_value)
		Token.RIGHT_SHIFT_EQUAL:
			if var_type == Typer.data_types["char"]:
				var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
				var new_value := WolfChar.new(current_value.value >> value.value)
				current_env.set_value(expr.name_token.lexeme, new_value)
			else:
				var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
				var new_value := WolfInt.new(current_value.value >> value.value)
				current_env.set_value(expr.name_token.lexeme, new_value)
		Token.PLUS_EQUAL:
			match var_type.base_type_name:
				"char":
					var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
					var new_value := WolfChar.new(current_value.value + value.value)
					current_env.set_value(expr.name_token.lexeme, new_value)
				"int":
					var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
					var new_value := WolfInt.new(current_value.value + value.value)
					current_env.set_value(expr.name_token.lexeme, new_value)
				"float":
					var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
					var new_value := WolfFloat.new(current_value.value + value.value)
					current_env.set_value(expr.name_token.lexeme, new_value)
				"string":
					var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
					var new_value := WolfString.new(current_value.value + value.value)
					current_env.set_value(expr.name_token.lexeme, new_value)
		Token.MINUS_EQUAL:
			match var_type.base_type_name:
				"char":
					var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
					var new_value := WolfChar.new(current_value.value - value.value)
					current_env.set_value(expr.name_token.lexeme, new_value)
				"int":
					var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
					var new_value := WolfInt.new(current_value.value - value.value)
					current_env.set_value(expr.name_token.lexeme, new_value)
				"float":
					var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
					var new_value := WolfFloat.new(current_value.value - value.value)
					current_env.set_value(expr.name_token.lexeme, new_value)
		Token.STAR_EQUAL:
			match var_type.base_type_name:
				"char":
					var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
					var new_value := WolfChar.new(current_value.value * value.value)
					current_env.set_value(expr.name_token.lexeme, new_value)
				"int":
					var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
					var new_value := WolfInt.new(current_value.value * value.value)
					current_env.set_value(expr.name_token.lexeme, new_value)
				"float":
					var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
					var new_value := WolfFloat.new(current_value.value * value.value)
					current_env.set_value(expr.name_token.lexeme, new_value)
		Token.SLASH_EQUAL:
			match var_type.base_type_name:
				"char":
					var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
					var new_value := WolfChar.new(current_value.value / value.value)
					current_env.set_value(expr.name_token.lexeme, new_value)
				"int":
					var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
					var new_value := WolfInt.new(current_value.value / value.value)
					current_env.set_value(expr.name_token.lexeme, new_value)
				"float":
					var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
					var new_value := WolfFloat.new(current_value.value / value.value)
					current_env.set_value(expr.name_token.lexeme, new_value)
		Token.PERCENT_EQUAL:
			match var_type.base_type_name:
				"char":
					var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
					var new_value := WolfChar.new(posmod(current_value.value, value.value))
					current_env.set_value(expr.name_token.lexeme, new_value)
				"int":
					var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
					var new_value := WolfInt.new(posmod(current_value.value, value.value))
					current_env.set_value(expr.name_token.lexeme, new_value)
				"float":
					var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
					var new_value := WolfFloat.new(fposmod(current_value.value, value.value))
					current_env.set_value(expr.name_token.lexeme, new_value)
		Token.EXPONENT_EQUAL:
			match var_type.base_type_name:
				"char":
					var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
					var new_value := WolfChar.new(current_value.value ** value.value)
					current_env.set_value(expr.name_token.lexeme, new_value)
				"int":
					var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
					var new_value := WolfInt.new(current_value.value ** value.value)
					current_env.set_value(expr.name_token.lexeme, new_value)
				"float":
					var current_value: WolfValue = current_env.get_value(expr.name_token.lexeme)
					var new_value := WolfFloat.new(pow(current_value.value, value.value))
					current_env.set_value(expr.name_token.lexeme, new_value)
	
	return current_env.get_value(expr.name_token.lexeme)


func is_truthy(value: WolfValue) -> bool:
	match value._get_type().base_type_name:
		"bool":
			return value.value
		"int":
			return value.value != 0
		"float":
			return value.value != 0
		"string":
			return value.value != ""
		"char":
			return value.value == 0
		"null":
			return false
		_:
			return true
