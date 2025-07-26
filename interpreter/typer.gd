class_name Typer
extends RefCounted

static var data_types: Dictionary[String, WolfType] = {}

## A reference to the interpreter which created this
var interpreter: Interpreter

var current_env: WolfEnvironment


static func load_data_types() -> void:
	# Any: The base type of literally everything
	data_types["any"] = WolfType.new("any", null, 0, [])
	
	# Any's two children: void and value
	# Void is for functions with no return
	data_types["void"] = WolfType.new("void", data_types["any"], 0, [])
	data_types["any"].add_child_type(data_types["void"])
	# Value is for any value
	data_types["value"] = WolfType.new("value", data_types["any"], 0, [])
	data_types["any"].add_child_type(data_types["value"])
	
	# The types of value
	
	# True or false
	data_types["bool"] = WolfType.new("bool", data_types["value"], 0, [])
	data_types["value"].add_child_type(data_types["bool"])
	# Text
	data_types["string"] = WolfType.new("string", data_types["value"], 0, [])
	data_types["value"].add_child_type(data_types["string"])
	
	# Numbers
	data_types["num"] = WolfType.new("num", data_types["value"], 0, [])
	data_types["value"].add_child_type(data_types["num"])
	# Ints, chars, and floats are all numbers
	# 64 bit integer
	data_types["int"] = WolfType.new("int", data_types["num"], 0, [])
	data_types["num"].add_child_type(data_types["int"])
	# 8 bit unsigned integer. Also an ascii character
	data_types["char"] = WolfType.new("char", data_types["num"], 0, [])
	data_types["num"].add_child_type(data_types["char"])
	# A 64 bit floating point number
	data_types["float"] = WolfType.new("float", data_types["num"], 0, [])
	data_types["num"].add_child_type(data_types["float"])
	
	# Types with parameters
	# A function which can be called
	data_types["callable"] = WolfType.new("callable", data_types["value"], 1, [])
	data_types["value"].add_child_type(data_types["callable"])
	
	# Nullable is special as it parents any value which can be null
	data_types["nullable"] = WolfType.new("nullable", data_types["value"], 0, [])
	data_types["value"].add_child_type(data_types["nullable"])


func type_check_statements(statements: Array[Statement]) -> void:
	if not current_env:
		current_env = interpreter.environment
	
	for statement in statements:
		type_check_statement(statement)


func type_check_statement(statement: Statement) -> void:
	if statement is Statement.Declaration:
		type_check_declaration_statement(statement)
	elif statement is Statement.ExprStmt:
		type_check_expr_statement(statement)
	elif statement is Statement.Block:
		type_check_block_statement(statement)
	elif statement is Statement.If:
		type_check_if_statement(statement)
	elif statement is Statement.While:
		type_check_while_statement(statement)
	elif statement is Statement.ForRange:
		type_check_for_range_statement(statement)


func type_check_expr_statement(statement: Statement.ExprStmt) -> void:
	get_type(statement.expr)
	return


func type_check_declaration_statement(statement: Statement.Declaration) -> void:
	if statement.initializer:
		var value_type: WolfType = get_type(statement.initializer)
		
		if value_type != statement.data_type:
			var value_is_num: bool = value_type.inherits(data_types["num"])
			var var_is_num: bool = statement.data_type.inherits(data_types["num"])
			
			if value_is_num and var_is_num:
				var old_init: Expr = statement.initializer
				var data_type: WolfType = statement.data_type
				var line_num: int = statement.line_start
				
				statement.initializer = Expr.Conversion.new(old_init, data_type, line_num)
				return
			
			var msg: String = "Cannot set variable of type %s to value of type %s"
			msg = msg % [statement.data_type, value_type]
			interpreter.error_handler.error(statement.line_start, msg)
	return


func type_check_block_statement(statement: Statement.Block) -> void:
	current_env = statement.environment
	type_check_statements(statement.statements)
	current_env = current_env.parent_environment
	return


func type_check_if_statement(statement: Statement.If) -> void:
	get_type(statement.condition)
	statement.condition = Expr.Conversion.new(statement.condition, data_types["bool"], 
			statement.line_start)
	type_check_block_statement(statement.block)
	
	for i in len(statement.elif_blocks):
		var cond: Expr = statement.elif_conds[i]
		get_type(cond)
		statement.elif_conds[i] = Expr.Conversion.new(cond, data_types["bool"], 
				statement.elif_lines[i])
		type_check_block_statement(statement.elif_blocks[i])
	
	if statement.else_block:
		type_check_block_statement(statement.else_block)
	return


func type_check_while_statement(statement: Statement.While) -> void:
	get_type(statement.condition)
	statement.condition = Expr.Conversion.new(statement.condition, data_types["bool"], 
			statement.line_start)
	type_check_block_statement(statement.block)
	return


func type_check_for_range_statement(statement: Statement.ForRange) -> void:
	if not statement.var_type.inherits(Typer.data_types["num"]):
		var msg: String = "Cannot convert range values to %s" % statement.var_type
		interpreter.error_handler.error(statement.line_start, msg)
	
	var start_type: WolfType = get_type(statement.start)
	if start_type.inherits(Typer.data_types["num"]):
		if start_type != Typer.data_types["int"]:
			statement.start = Expr.Conversion.new(statement.start, data_types["int"], 
					statement.line_start)
	else:
		var msg: String = "Cannot implicitly convert %s to int" % start_type
		interpreter.error_handler.error(statement.line_start, msg)
	
	var end_type: WolfType = get_type(statement.end)
	if end_type.inherits(Typer.data_types["num"]):
		if end_type != Typer.data_types["int"]:
			statement.end = Expr.Conversion.new(statement.end, data_types["int"], 
					statement.line_start)
	else:
		var msg: String = "Cannot implicitly convert %s to int" % end_type
		interpreter.error_handler.error(statement.line_start, msg)
	
	var step_type: WolfType = get_type(statement.step)
	if step_type.inherits(Typer.data_types["num"]):
		if step_type != Typer.data_types["int"]:
			statement.step = Expr.Conversion.new(statement.step, data_types["int"], 
					statement.line_start)
	else:
		var msg: String = "Cannot implicitly convert %s to int" % step_type
		interpreter.error_handler.error(statement.line_start, msg)
	
	type_check_block_statement(statement.block)
	return


func get_type(expr: Expr) -> WolfType:
	if expr is Expr.Literal:
		return get_literal_type(expr)
	elif expr is Expr.Variable:
		return get_variable_type(expr)
	elif expr is Expr.Grouping:
		return get_grouped_type(expr)
	elif expr is Expr.Call:
		return get_call_type(expr)
	elif expr is Expr.Conversion:
		return get_converted_type(expr)
	elif expr is Expr.Unary:
		return get_unary_type(expr)
	elif expr is Expr.Binary:
		return get_binary_type(expr)
	elif expr is Expr.Ternary:
		return get_ternary_type(expr)
	elif expr is Expr.Assignment:
		return get_assignment_type(expr)
	
	return null


func get_literal_type(expr: Expr.Literal) -> WolfType:
	var literal_type: WolfType = expr.literal_token.literal_value._get_type()
	
	expr.ret_type = literal_type
	return literal_type


func get_variable_type(expr: Expr.Variable) -> WolfType:
	var variable_type: WolfType = current_env.get_type(expr.name_token.lexeme)
	
	expr.ret_type = variable_type
	return variable_type


func get_grouped_type(expr: Expr.Grouping) -> WolfType:
	var ret_type: WolfType = get_type(expr.grouped_expr)
	
	expr.ret_type = ret_type
	return ret_type


func get_call_type(expr: Expr.Call) -> WolfType:
	var callable_type: WolfType = get_type(expr.callable_expr)
	if callable_type != data_types["callable"]:
		var msg: String = "Cannot call %s" % callable_type
		interpreter.error_handler.error(expr.close_paren.line_num, msg)
		return callable_type
	
	var callable_name: String
	var callable: WolfCallable
	
	if expr.callable_expr is Expr.Variable:
		if current_env.var_has_value(expr.callable_expr.name_token.lexeme):
			callable = current_env.get_value(expr.callable_expr.name_token.lexeme)
			callable_name = expr.callable_expr.name_token.lexeme
		else:
			for arg: Expr in expr.args:
				get_type(arg)
			return data_types["any"]
	
	expr.callable = callable
	
	var arg_types: Array[WolfType]
	
	for arg: Expr in expr.args:
		arg_types.append(get_type(arg))
	
	var callable_def: CallableDefenition = callable._def_to_use(arg_types)
	
	if not callable_def:
		var msg: String = "Invalid args for %s" % callable_name
		interpreter.error_handler.error(expr.close_paren.line_num, msg)
		return data_types["callable"]
	
	var ret_type: WolfType = callable_def.return_type
	
	expr.ret_type = ret_type
	return ret_type


func get_converted_type(expr: Expr.Conversion) -> WolfType:
	# Children still must be type-checked
	get_type(expr.converted_expr)
	
	var ret_type: WolfType = expr.new_type
	
	expr.ret_type = ret_type
	return ret_type


func get_unary_type(expr: Expr.Unary) -> WolfType:
	match expr.op_token.token_type:
		Token.NOT:
			return get_not_type(expr)
		Token.MINUS:
			return get_unary_minus_type(expr)
		Token.BIT_NOT:
			return get_bit_not_type(expr)
	
	var ret_type: WolfType = get_type(expr.right)
	
	expr.ret_type = ret_type
	return ret_type


func get_not_type(expr: Expr.Unary) -> WolfType:
	# Children still must be type-checked
	get_type(expr.right)
	
	# Convert operand to bool
	expr.right = Expr.Conversion.new(expr.right, data_types["bool"], expr.op_token.line_num)
	
	expr.ret_type = data_types["bool"]
	return data_types["bool"]


func get_unary_minus_type(expr: Expr.Unary) -> WolfType:
	var ret_type: WolfType = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if ret_type.base_type_name not in ["int", "float"]:
		var msg: String = "Can't perform unary - on %s" % ret_type
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		# Assume that the minus just wasn't meant to be there for whatever uses this
		expr.ret_type = ret_type
		return ret_type
	
	expr.ret_type = ret_type
	return ret_type


func get_bit_not_type(expr: Expr.Unary) -> WolfType:
	var ret_type: WolfType = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if ret_type.base_type_name not in ["int", "char"]:
		var msg: String = "Can't perform bitwise negation on %s" % ret_type
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		# Assume that the ~ just wasn't meant to be there for whatever uses this
		expr.ret_type = ret_type
		return ret_type
	
	expr.ret_type = ret_type
	return ret_type


func get_binary_type(expr: Expr.Binary) -> WolfType:
	match expr.op_token.token_type:
		Token.PLUS:
			return get_plus_type(expr)
		Token.MINUS:
			return get_binary_minus_type(expr)
		Token.STAR:
			return get_multiplication_type(expr)
		Token.SLASH:
			return get_division_type(expr)
		Token.PERCENT:
			return get_modulo_type(expr)
		Token.EXPONENT:
			return get_exponentiation_type(expr)
		Token.BIT_AND:
			return get_bit_and_type(expr)
		Token.BIT_OR:
			return get_bit_or_type(expr)
		Token.BIT_XOR:
			return get_bit_xor_type(expr)
		Token.AND:
			return get_and_type(expr)
		Token.OR:
			return get_or_type(expr)
		Token.XOR:
			return get_xor_type(expr)
		Token.NAND:
			return get_nand_type(expr)
		Token.NOR:
			return get_nor_type(expr)
		Token.XNOR:
			return get_xnor_type(expr)
		Token.MORE:
			return get_more_type(expr)
		Token.MORE_EQUAL:
			return get_more_equal_type(expr)
		Token.LESS:
			return get_less_type(expr)
		Token.LESS_EQUAL:
			return get_less_equal_type(expr)
		Token.COMP_EQUAL:
			return get_comp_equal_type(expr)
		Token.NOT_EQUAL:
			return get_not_equal_type(expr)
	
	var ret_type: WolfType = get_type(expr.left)
	
	expr.ret_type = ret_type
	return ret_type


func get_plus_type(expr: Expr.Binary) -> WolfType:
	var left_type: WolfType = get_type(expr.left)
	var right_type: WolfType = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if not (left_type.inherits(data_types["num"]) and right_type.inherits(data_types["num"])):
		if left_type == data_types["string"] and right_type == data_types["string"]:
			# Concatination is legal
			expr.ret_type = data_types["string"]
			return data_types["string"]
		
		var msg: String = "Can't perform + on %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		# Need to return something
		expr.ret_type = left_type
		return left_type
	
	if left_type == right_type:
		expr.ret_type = left_type
		return left_type
	
	var conv_type: WolfType = _get_highest_priority_num_type(left_type, right_type)
	
	expr.left = Expr.Conversion.new(expr.left, conv_type, expr.op_token.line_num)
	expr.right = Expr.Conversion.new(expr.right, conv_type, expr.op_token.line_num)
	
	expr.ret_type = conv_type
	return conv_type


func get_binary_minus_type(expr: Expr.Binary) -> WolfType:
	var left_type: WolfType = get_type(expr.left)
	var right_type: WolfType = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if not (left_type.inherits(data_types["num"]) and right_type.inherits(data_types["num"])):
		var msg: String = "Can't perform subtraction on %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		# Need to return something
		expr.ret_type = left_type
		return left_type
	
	if left_type == right_type:
		expr.ret_type = left_type
		return left_type
	
	var conv_type: WolfType = _get_highest_priority_num_type(left_type, right_type)
	
	expr.left = Expr.Conversion.new(expr.left, conv_type, expr.op_token.line_num)
	expr.right = Expr.Conversion.new(expr.right, conv_type, expr.op_token.line_num)
	
	expr.ret_type = conv_type
	return conv_type


func get_multiplication_type(expr: Expr.Binary) -> WolfType:
	var left_type: WolfType = get_type(expr.left)
	var right_type: WolfType = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if not (left_type.inherits(data_types["num"]) and right_type.inherits(data_types["num"])):
		var msg: String = "Can't perform multiplication on %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		# Need to return something
		expr.ret_type = left_type
		return left_type
	
	if left_type == right_type:
		expr.ret_type = left_type
		return left_type
	
	var conv_type: WolfType = _get_highest_priority_num_type(left_type, right_type)
	
	expr.left = Expr.Conversion.new(expr.left, conv_type, expr.op_token.line_num)
	expr.right = Expr.Conversion.new(expr.right, conv_type, expr.op_token.line_num)
	
	expr.ret_type = conv_type
	return conv_type


func get_division_type(expr: Expr.Binary) -> WolfType:
	var left_type: WolfType = get_type(expr.left)
	var right_type: WolfType = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if not (left_type.inherits(data_types["num"]) and right_type.inherits(data_types["num"])):
		var msg: String = "Can't perform division on %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		# Need to return something
		expr.ret_type = left_type
		return left_type
	
	if left_type == right_type:
		expr.ret_type = left_type
		return left_type
	
	var conv_type: WolfType = _get_highest_priority_num_type(left_type, right_type)
	
	expr.left = Expr.Conversion.new(expr.left, conv_type, expr.op_token.line_num)
	expr.right = Expr.Conversion.new(expr.right, conv_type, expr.op_token.line_num)
	
	expr.ret_type = conv_type
	return conv_type


func get_modulo_type(expr: Expr.Binary) -> WolfType:
	var left_type: WolfType = get_type(expr.left)
	var right_type: WolfType = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if not (left_type.inherits(data_types["num"]) and right_type.inherits(data_types["num"])):
		var msg: String = "Can't perform modulo on %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		# Need to return something
		expr.ret_type = left_type
		return left_type
	
	if left_type == right_type:
		expr.ret_type = left_type
		return left_type
	
	var conv_type: WolfType = _get_highest_priority_num_type(left_type, right_type)
	
	expr.left = Expr.Conversion.new(expr.left, conv_type, expr.op_token.line_num)
	expr.right = Expr.Conversion.new(expr.right, conv_type, expr.op_token.line_num)
	
	expr.ret_type = conv_type
	return conv_type


func get_exponentiation_type(expr: Expr.Binary) -> WolfType:
	var left_type: WolfType = get_type(expr.left)
	var right_type: WolfType = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if not (left_type.inherits(data_types["num"]) and right_type.inherits(data_types["num"])):
		var msg: String = "Can't perform exponentiation on %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		# Need to return something
		expr.ret_type = left_type
		return left_type
	
	if left_type == right_type:
		expr.ret_type = left_type
		return left_type
	
	var conv_type: WolfType = _get_highest_priority_num_type(left_type, right_type)
	
	expr.left = Expr.Conversion.new(expr.left, conv_type, expr.op_token.line_num)
	expr.right = Expr.Conversion.new(expr.right, conv_type, expr.op_token.line_num)
	
	expr.ret_type = conv_type
	return conv_type


func get_bit_and_type(expr: Expr.Binary) -> WolfType:
	var left_type: WolfType = get_type(expr.left)
	var right_type: WolfType = get_type(expr.right)
	
	var integers: Array[WolfType] = [data_types["int"], data_types["char"]]
	
	# Check for invalid input. If the input type is bad, error out
	if not (left_type in integers and right_type in integers):
		var msg: String = "Can't perform bitwise or on %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		# Need to return something
		expr.ret_type = left_type
		return left_type
	
	if left_type == right_type:
		expr.ret_type = left_type
		return left_type
	
	expr.left = Expr.Conversion.new(expr.left, data_types["int"], expr.op_token.line_num)
	expr.right = Expr.Conversion.new(expr.right, data_types["int"], expr.op_token.line_num)
	
	expr.ret_type = data_types["int"]
	return data_types["int"]


func get_bit_or_type(expr: Expr.Binary) -> WolfType:
	var left_type: WolfType = get_type(expr.left)
	var right_type: WolfType = get_type(expr.right)
	
	var integers: Array[WolfType] = [data_types["int"], data_types["char"]]
	
	# Check for invalid input. If the input type is bad, error out
	if not (left_type in integers and right_type in integers):
		var msg: String = "Can't perform bitwise or on %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		# Need to return something
		expr.ret_type = left_type
		return left_type
	
	if left_type == right_type:
		expr.ret_type = left_type
		return left_type
	
	expr.left = Expr.Conversion.new(expr.left, data_types["int"], expr.op_token.line_num)
	expr.right = Expr.Conversion.new(expr.right, data_types["int"], expr.op_token.line_num)
	
	expr.ret_type = data_types["int"]
	return data_types["int"]


func get_bit_xor_type(expr: Expr.Binary) -> WolfType:
	var left_type: WolfType = get_type(expr.left)
	var right_type: WolfType = get_type(expr.right)
	
	var integers: Array[WolfType] = [data_types["int"], data_types["char"]]
	
	# Check for invalid input. If the input type is bad, error out
	if not (left_type in integers and right_type in integers):
		var msg: String = "Can't perform bitwise or on %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		# Need to return something
		expr.ret_type = left_type
		return left_type
	
	if left_type == right_type:
		expr.ret_type = left_type
		return left_type
	
	expr.left = Expr.Conversion.new(expr.left, data_types["int"], expr.op_token.line_num)
	expr.right = Expr.Conversion.new(expr.right, data_types["int"], expr.op_token.line_num)
	
	expr.ret_type = data_types["int"]
	return data_types["int"]


func get_and_type(expr: Expr.Binary) -> WolfType:
	var left_type: WolfType = get_type(expr.left)
	var right_type: WolfType = get_type(expr.right)
	
	# If both inputs have the same type, that will be the return type
	if left_type == right_type:
		expr.ret_type = left_type
		return left_type
	
	# Otherwise, could be either type so we use mixed
	expr.ret_type = left_type.get_least_common_ancestor(right_type)
	return left_type.get_least_common_ancestor(right_type)


func get_or_type(expr: Expr.Binary) -> WolfType:
	var left_type: WolfType = get_type(expr.left)
	var right_type: WolfType = get_type(expr.right)
	
	# If both inputs have the same type, that will be the return type
	if left_type == right_type:
		expr.ret_type = left_type
		return left_type
	
	# Otherwise, could be either type so we use mixed
	expr.ret_type = left_type.get_least_common_ancestor(right_type)
	return left_type.get_least_common_ancestor(right_type)


func get_xor_type(expr: Expr.Binary) -> WolfType:
	# Type check inputs (Important that nested exprs are checked)
	get_type(expr.left)
	get_type(expr.right)
	
	# Convert inputs to bools
	expr.left = Expr.Conversion.new(expr.left, data_types["bool"], expr.op_token.line_num)
	expr.right = Expr.Conversion.new(expr.right, data_types["bool"], expr.op_token.line_num)
	
	# Otherwise, could be either type so we use mixed
	expr.ret_type = data_types["bool"]
	return data_types["bool"]


func get_nand_type(expr: Expr.Binary) -> WolfType:
	# Type check inputs (Important that nested exprs are checked)
	get_type(expr.left)
	get_type(expr.right)
	
	# Convert inputs to bools
	expr.left = Expr.Conversion.new(expr.left, data_types["bool"], expr.op_token.line_num)
	expr.right = Expr.Conversion.new(expr.right, data_types["bool"], expr.op_token.line_num)
	
	# Otherwise, could be either type so we use mixed
	expr.ret_type = data_types["bool"]
	return data_types["bool"]


func get_nor_type(expr: Expr.Binary) -> WolfType:
	# Type check inputs (Important that nested exprs are checked)
	get_type(expr.left)
	get_type(expr.right)
	
	# Convert inputs to bools
	expr.left = Expr.Conversion.new(expr.left, data_types["bool"], expr.op_token.line_num)
	expr.right = Expr.Conversion.new(expr.right, data_types["bool"], expr.op_token.line_num)
	
	# Otherwise, could be either type so we use mixed
	expr.ret_type = data_types["bool"]
	return data_types["bool"]


func get_xnor_type(expr: Expr.Binary) -> WolfType:
	# Type check inputs (Important that nested exprs are checked)
	get_type(expr.left)
	get_type(expr.right)
	
	# Convert inputs to bools
	expr.left = Expr.Conversion.new(expr.left, data_types["bool"], expr.op_token.line_num)
	expr.right = Expr.Conversion.new(expr.right, data_types["bool"], expr.op_token.line_num)
	
	# Otherwise, could be either type so we use mixed
	expr.ret_type = data_types["bool"]
	return data_types["bool"]


func get_more_type(expr: Expr.Binary) -> WolfType:
	var left_type: WolfType = get_type(expr.left)
	var right_type: WolfType = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if not (left_type.inherits(data_types["num"]) and right_type.inherits(data_types["num"])):
		var msg: String = "Can't perform greater than on %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		expr.ret_type = data_types["bool"]
		return data_types["bool"]
	
	if left_type == right_type:
		expr.ret_type = data_types["bool"]
		return data_types["bool"]
	
	var conv_type: WolfType = _get_highest_priority_num_type(left_type, right_type)
	
	expr.left = Expr.Conversion.new(expr.left, conv_type, expr.op_token.line_num)
	expr.right = Expr.Conversion.new(expr.right, conv_type, expr.op_token.line_num)
	
	expr.ret_type = data_types["bool"]
	return data_types["bool"]


func get_more_equal_type(expr: Expr.Binary) -> WolfType:
	var left_type: WolfType = get_type(expr.left)
	var right_type: WolfType = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if not (left_type.inherits(data_types["num"]) and right_type.inherits(data_types["num"])):
		var msg: String = "Can't perform greater or equal on %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		expr.ret_type = data_types["bool"]
		return data_types["bool"]
	
	if left_type == right_type:
		expr.ret_type = data_types["bool"]
		return data_types["bool"]
	
	var conv_type: WolfType = _get_highest_priority_num_type(left_type, right_type)
	
	expr.left = Expr.Conversion.new(expr.left, conv_type, expr.op_token.line_num)
	expr.right = Expr.Conversion.new(expr.right, conv_type, expr.op_token.line_num)
	
	expr.ret_type = data_types["bool"]
	return data_types["bool"]


func get_less_type(expr: Expr.Binary) -> WolfType:
	var left_type: WolfType = get_type(expr.left)
	var right_type: WolfType = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if not (left_type.inherits(data_types["num"]) and right_type.inherits(data_types["num"])):
		var msg: String = "Can't perform less than on %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		expr.ret_type = data_types["bool"]
		return data_types["bool"]
	
	if left_type == right_type:
		expr.ret_type = data_types["bool"]
		return data_types["bool"]
	
	var conv_type: WolfType = _get_highest_priority_num_type(left_type, right_type)
	
	expr.left = Expr.Conversion.new(expr.left, conv_type, expr.op_token.line_num)
	expr.right = Expr.Conversion.new(expr.right, conv_type, expr.op_token.line_num)
	
	expr.ret_type = data_types["bool"]
	return data_types["bool"]


func get_less_equal_type(expr: Expr.Binary) -> WolfType:
	var left_type: WolfType = get_type(expr.left)
	var right_type: WolfType = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if not (left_type.inherits(data_types["num"]) and right_type.inherits(data_types["num"])):
		var msg: String = "Can't perform less or equal on %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		expr.ret_type = data_types["bool"]
		return data_types["bool"]
	
	if left_type == right_type:
		expr.ret_type = data_types["bool"]
		return data_types["bool"]
	
	var conv_type: WolfType = _get_highest_priority_num_type(left_type, right_type)
	
	expr.left = Expr.Conversion.new(expr.left, conv_type, expr.op_token.line_num)
	expr.right = Expr.Conversion.new(expr.right, conv_type, expr.op_token.line_num)
	
	expr.ret_type = data_types["bool"]
	return data_types["bool"]


func get_comp_equal_type(expr: Expr.Binary) -> WolfType:
	var left_type: WolfType = get_type(expr.left)
	var right_type: WolfType = get_type(expr.right)
	
	if left_type == right_type:
		expr.ret_type = data_types["bool"]
		return data_types["bool"]
	
	# Check for invalid input. If the input type is bad, error out
	if not (left_type.inherits(data_types["num"]) and right_type.inherits(data_types["num"])):
		var msg: String = "Can't perform == on %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		expr.ret_type = data_types["bool"]
		return data_types["bool"]
	
	var conv_type: WolfType = _get_highest_priority_num_type(left_type, right_type)
	
	expr.left = Expr.Conversion.new(expr.left, conv_type, expr.op_token.line_num)
	expr.right = Expr.Conversion.new(expr.right, conv_type, expr.op_token.line_num)
	
	expr.ret_type = data_types["bool"]
	return data_types["bool"]


func get_not_equal_type(expr: Expr.Binary) -> WolfType:
	var left_type: WolfType = get_type(expr.left)
	var right_type: WolfType = get_type(expr.right)
	
	if left_type == right_type:
		expr.ret_type = data_types["bool"]
		return data_types["bool"]
	
	# Check for invalid input. If the input type is bad, error out
	if not (left_type.inherits(data_types["num"]) and right_type.inherits(data_types["num"])):
		var msg: String = "Can't perform != on %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		expr.ret_type = data_types["bool"]
		return data_types["bool"]
	
	var conv_type: WolfType = _get_highest_priority_num_type(left_type, right_type)
	
	expr.left = Expr.Conversion.new(expr.left, conv_type, expr.op_token.line_num)
	expr.right = Expr.Conversion.new(expr.right, conv_type, expr.op_token.line_num)
	
	expr.ret_type = data_types["bool"]
	return data_types["bool"]


func get_ternary_type(expr: Expr.Ternary) -> WolfType:
	var left_type: WolfType = get_type(expr.true_exp)
	var right_type: WolfType = get_type(expr.false_exp)
	
	var cond_type: WolfType = get_type(expr.cond)
	
	if cond_type != data_types["bool"]:
		expr.cond = Expr.Conversion.new(expr.cond, data_types["bool"], expr.line_num)
	
	# If both inputs have the same type, that will be the return type
	if left_type == right_type:
		expr.ret_type = left_type
		return left_type
	
	# Otherwise, could be either type so we use mixed
	expr.ret_type = left_type.get_least_common_ancestor(right_type)
	return expr.ret_type


func get_assignment_type(expr: Expr.Assignment) -> WolfType:
	var var_type: WolfType = current_env.get_type(expr.name_token.lexeme)
	var value_type: WolfType = get_type(expr.value_expr)
	
	# Check for invalid var type based on operator
	match expr.op_token.token_type:
		Token.SET_EQUAL:
			pass
		Token.BIT_AND_EQUAL:
			var integers: Array[WolfType] = [data_types["int"], data_types["char"]]
			if var_type not in integers or value_type not in integers:
				var msg: String = "Cannot perform '&=' on var of type %s with value of type %s"
				msg %= [var_type, value_type]
				interpreter.error_handler.error(expr.op_token.line_num, msg)
		Token.BIT_OR_EQUAL:
			var integers: Array[WolfType] = [data_types["int"], data_types["char"]]
			if var_type not in integers or value_type not in integers:
				var msg: String = "Cannot perform '|=' on var of type %s with value of type %s"
				msg %= [var_type, value_type]
				interpreter.error_handler.error(expr.op_token.line_num, msg)
		Token.BIT_XOR_EQUAL:
			var integers: Array[WolfType] = [data_types["int"], data_types["char"]]
			if var_type not in integers or value_type not in integers:
				var msg: String = "Cannot perform '^=' on var of type %s with value of type %s"
				msg %= [var_type, value_type]
				interpreter.error_handler.error(expr.op_token.line_num, msg)
		Token.LEFT_SHIFT_EQUAL:
			var integers: Array[WolfType] = [data_types["int"], data_types["char"]]
			if var_type not in integers or value_type not in integers:
				var msg: String = "Cannot perform '<<=' on var of type %s with value of type %s"
				msg %= [var_type, value_type]
				interpreter.error_handler.error(expr.op_token.line_num, msg)
		Token.RIGHT_SHIFT_EQUAL:
			var integers: Array[WolfType] = [data_types["int"], data_types["char"]]
			if var_type not in integers or value_type not in integers:
				var msg: String = "Cannot perform '>>=' on var of type %s with value of type %s"
				msg %= [var_type, value_type]
				interpreter.error_handler.error(expr.op_token.line_num, msg)
		Token.PLUS_EQUAL:
			var value_is_num: bool = value_type.inherits(data_types["num"])
			var var_is_num: bool = var_type.inherits(data_types["num"])
			var both_strings: bool
			both_strings = var_type == data_types["string"] or value_type == data_types["string"]
			
			if not (value_is_num and var_is_num or both_strings):
				var msg: String = "Cannot perform '+=' on var of type %s with value of type %s"
				msg %= [var_type, value_type]
				interpreter.error_handler.error(expr.op_token.line_num, msg)
		Token.MINUS_EQUAL:
			var value_is_num: bool = value_type.inherits(data_types["num"])
			var var_is_num: bool = var_type.inherits(data_types["num"])
			
			if not (value_is_num and var_is_num):
				var msg: String = "Cannot perform '-=' on var of type %s with value of type %s"
				msg %= [var_type, value_type]
				interpreter.error_handler.error(expr.op_token.line_num, msg)
		Token.STAR_EQUAL:
			var value_is_num: bool = value_type.inherits(data_types["num"])
			var var_is_num: bool = var_type.inherits(data_types["num"])
			
			if not (value_is_num and var_is_num):
				var msg: String = "Cannot perform '*=' on var of type %s with value of type %s"
				msg %= [var_type, value_type]
				interpreter.error_handler.error(expr.op_token.line_num, msg)
		Token.SLASH_EQUAL:
			var value_is_num: bool = value_type.inherits(data_types["num"])
			var var_is_num: bool = var_type.inherits(data_types["num"])
			
			if not (value_is_num and var_is_num):
				var msg: String = "Cannot perform '/=' on var of type %s with value of type %s"
				msg %= [var_type, value_type]
				interpreter.error_handler.error(expr.op_token.line_num, msg)
		Token.PERCENT_EQUAL:
			var value_is_num: bool = value_type.inherits(data_types["num"])
			var var_is_num: bool = var_type.inherits(data_types["num"])
			
			if not (value_is_num and var_is_num):
				var msg: String = "Cannot perform '%=' on var of type %s with value of type %s"
				msg %= [var_type, value_type]
				interpreter.error_handler.error(expr.op_token.line_num, msg)
		Token.EXPONENT_EQUAL:
			var value_is_num: bool = value_type.inherits(data_types["num"])
			var var_is_num: bool = var_type.inherits(data_types["num"])
			
			if not (value_is_num and var_is_num):
				var msg: String = "Cannot perform '**=' on var of type %s with value of type %s"
				msg %= [var_type, value_type]
				interpreter.error_handler.error(expr.op_token.line_num, msg)
	
	if value_type != var_type:
		var value_is_num: bool = value_type.inherits(data_types["num"])
		var var_is_num: bool = var_type.inherits(data_types["num"])
		
		if value_is_num and var_is_num:
			var old_value: Expr = expr.value_expr
			var line_num: int = expr.op_token.line_num
			
			expr.value_expr = Expr.Conversion.new(old_value, var_type, line_num)
			return var_type
		
		var msg: String = "Cannot assign var of type %s with '%s' using value of type %s"
		msg = msg % [var_type, expr.op_token.lexeme, value_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
	
	return var_type


func _get_highest_priority_num_type(type_a: WolfType, type_b: WolfType) -> WolfType:
	if Typer.data_types["float"] in [type_a, type_b]:
		return Typer.data_types["float"]
	
	return Typer.data_types["int"]
