class_name Typer
extends RefCounted

## A reference to the interpreter which created this
var interpreter: Interpreter


func type_check(expr: Expr) -> Expr:
	get_type(expr)
	return expr


func get_type(expr: Expr) -> String:
	if expr is Expr.Literal:
		return get_literal_type(expr)
	elif expr is Expr.Grouping:
		return get_grouped_type(expr)
	elif expr is Expr.Conversion:
		return get_converted_type(expr)
	elif expr is Expr.Unary:
		return get_unary_type(expr)
	elif expr is Expr.Binary:
		return get_binary_type(expr)
	elif expr is Expr.Ternary:
		return get_ternary_type(expr)
	return ""


func get_literal_type(expr: Expr.Literal) -> String:
	var literal_type: String = expr.literal_token.literal_type
	
	expr.ret_type = literal_type
	return literal_type


func get_grouped_type(expr: Expr.Grouping) -> String:
	var ret_type: String = get_type(expr.grouped_expr)
	
	expr.ret_type = ret_type
	return ret_type


func get_converted_type(expr: Expr.Conversion) -> String:
	# Children still must be type-checked
	get_type(expr.converted_expr)
	
	var ret_type: String = expr.new_type
	
	expr.ret_type = ret_type
	return ret_type


func get_unary_type(expr: Expr.Unary) -> String:
	match expr.op_token.token_type:
		Token.NOT:
			return get_not_type(expr)
		Token.MINUS:
			return get_unary_minus_type(expr)
		Token.BIT_NOT:
			return get_bit_not_type(expr)
	
	var ret_type: String = get_type(expr.right)
	
	expr.ret_type = ret_type
	return ret_type


func get_not_type(expr: Expr.Unary) -> String:
	# Children still must be type-checked
	get_type(expr.right)
	
	# Convert operand to bool
	expr.right = Expr.Conversion.new(expr.right, "bool", expr.op_token.line_num)
	
	expr.ret_type = "bool"
	return "bool"


func get_unary_minus_type(expr: Expr.Unary) -> String:
	var ret_type: String = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if ret_type not in ["int", "float"]:
		var msg: String = "Can't perform unary - on %s" % ret_type
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		# Assume that the minus just wasn't meant to be there for whatever uses this
		expr.ret_type = ret_type
		return ret_type
	
	expr.ret_type = ret_type
	return ret_type


func get_bit_not_type(expr: Expr.Unary) -> String:
	var ret_type: String = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if ret_type not in ["int", "char"]:
		var msg: String = "Can't perform bitwise negation on %s" % ret_type
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		# Assume that the ~ just wasn't meant to be there for whatever uses this
		expr.ret_type = ret_type
		return ret_type
	
	expr.ret_type = ret_type
	return ret_type


func get_binary_type(expr: Expr.Binary) -> String:
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
	
	var ret_type: String = get_type(expr.left)
	
	expr.ret_type = ret_type
	return ret_type


func get_plus_type(expr: Expr.Binary) -> String:
	var left_type: String = get_type(expr.left)
	var right_type: String = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if left_type not in ["int", "char", "float"] or right_type not in ["int", "char", "float"]:
		if left_type == "string" and right_type == "string":
			# Concatination is legal
			expr.ret_type = "string"
			return "string"
		
		var msg: String = "Can't perform + on %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		# Need to return something
		expr.ret_type = left_type
		return left_type
	
	if left_type == "float" or right_type == "float":
		expr.left = Expr.Conversion.new(expr.left, "float", expr.op_token.line_num)
		expr.right = Expr.Conversion.new(expr.right, "float", expr.op_token.line_num)
		
		expr.ret_type = "float"
		return "float"
	
	if left_type == "int" or right_type == "int":
		expr.left = Expr.Conversion.new(expr.left, "int", expr.op_token.line_num)
		expr.right = Expr.Conversion.new(expr.right, "int", expr.op_token.line_num)
		
		expr.ret_type = "int"
		return "int"
	
	expr.ret_type = "char"
	return "char"


func get_binary_minus_type(expr: Expr.Binary) -> String:
	var left_type: String = get_type(expr.left)
	var right_type: String = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if left_type not in ["int", "char", "float"] or right_type not in ["int", "char", "float"]:
		var msg: String = "Can't perform subtraction on %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		# Need to return something
		expr.ret_type = left_type
		return left_type
	
	if left_type == "float" or right_type == "float":
		expr.left = Expr.Conversion.new(expr.left, "float", expr.op_token.line_num)
		expr.right = Expr.Conversion.new(expr.right, "float", expr.op_token.line_num)
		
		expr.ret_type = "float"
		return "float"
	
	if left_type == "int" or right_type == "int":
		expr.left = Expr.Conversion.new(expr.left, "int", expr.op_token.line_num)
		expr.right = Expr.Conversion.new(expr.right, "int", expr.op_token.line_num)
		
		expr.ret_type = "int"
		return "int"
	
	expr.ret_type = "char"
	return "char"


func get_multiplication_type(expr: Expr.Binary) -> String:
	var left_type: String = get_type(expr.left)
	var right_type: String = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if left_type not in ["int", "char", "float"] or right_type not in ["int", "char", "float"]:
		var msg: String = "Can't perform multiplication on %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		# Need to return something
		expr.ret_type = left_type
		return left_type
	
	if left_type == "float" or right_type == "float":
		expr.left = Expr.Conversion.new(expr.left, "float", expr.op_token.line_num)
		expr.right = Expr.Conversion.new(expr.right, "float", expr.op_token.line_num)
		
		expr.ret_type = "float"
		return "float"
	
	if left_type == "int" or right_type == "int":
		expr.left = Expr.Conversion.new(expr.left, "int", expr.op_token.line_num)
		expr.right = Expr.Conversion.new(expr.right, "int", expr.op_token.line_num)
		
		expr.ret_type = "int"
		return "int"
	
	expr.ret_type = "char"
	return "char"


func get_division_type(expr: Expr.Binary) -> String:
	var left_type: String = get_type(expr.left)
	var right_type: String = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if left_type not in ["int", "char", "float"] or right_type not in ["int", "char", "float"]:
		var msg: String = "Can't perform division on %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		# Need to return something
		expr.ret_type = left_type
		return left_type
	
	if left_type == "float" or right_type == "float":
		expr.left = Expr.Conversion.new(expr.left, "float", expr.op_token.line_num)
		expr.right = Expr.Conversion.new(expr.right, "float", expr.op_token.line_num)
		
		expr.ret_type = "float"
		return "float"
	
	if left_type == "int" or right_type == "int":
		expr.left = Expr.Conversion.new(expr.left, "int", expr.op_token.line_num)
		expr.right = Expr.Conversion.new(expr.right, "int", expr.op_token.line_num)
		
		expr.ret_type = "int"
		return "int"
	
	expr.ret_type = "char"
	return "char"


func get_modulo_type(expr: Expr.Binary) -> String:
	var left_type: String = get_type(expr.left)
	var right_type: String = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if left_type not in ["int", "char", "float"] or right_type not in ["int", "char", "float"]:
		var msg: String = "Can't perform modulo on %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		# Need to return something
		expr.ret_type = left_type
		return left_type
	
	if left_type == "float" or right_type == "float":
		expr.left = Expr.Conversion.new(expr.left, "float", expr.op_token.line_num)
		expr.right = Expr.Conversion.new(expr.right, "float", expr.op_token.line_num)
		
		expr.ret_type = "float"
		return "float"
	
	if left_type == "int" or right_type == "int":
		expr.left = Expr.Conversion.new(expr.left, "int", expr.op_token.line_num)
		expr.right = Expr.Conversion.new(expr.right, "int", expr.op_token.line_num)
		
		expr.ret_type = "int"
		return "int"
	
	expr.ret_type = "char"
	return "char"


func get_exponentiation_type(expr: Expr.Binary) -> String:
	var left_type: String = get_type(expr.left)
	var right_type: String = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if left_type not in ["int", "char", "float"] or right_type not in ["int", "char", "float"]:
		var msg: String = "Can't perform exponentiation on %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		# Need to return something
		expr.ret_type = left_type
		return left_type
	
	if left_type == "float" or right_type == "float":
		expr.left = Expr.Conversion.new(expr.left, "float", expr.op_token.line_num)
		expr.right = Expr.Conversion.new(expr.right, "float", expr.op_token.line_num)
		
		expr.ret_type = "float"
		return "float"
	
	if left_type == "int" or right_type == "int":
		expr.left = Expr.Conversion.new(expr.left, "int", expr.op_token.line_num)
		expr.right = Expr.Conversion.new(expr.right, "int", expr.op_token.line_num)
		
		expr.ret_type = "int"
		return "int"
	
	expr.ret_type = "char"
	return "char"


func get_bit_and_type(expr: Expr.Binary) -> String:
	var left_type: String = get_type(expr.left)
	var right_type: String = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if left_type not in ["int", "char"] or right_type not in ["int", "char"]:
		var msg: String = "Can't perform bitwise and on %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		# Need to return something
		expr.ret_type = left_type
		return left_type
	
	if left_type == "int" or right_type == "int":
		expr.left = Expr.Conversion.new(expr.left, "int", expr.op_token.line_num)
		expr.right = Expr.Conversion.new(expr.right, "int", expr.op_token.line_num)
		
		expr.ret_type = "int"
		return "int"
	
	expr.ret_type = "char"
	return "char"


func get_bit_or_type(expr: Expr.Binary) -> String:
	var left_type: String = get_type(expr.left)
	var right_type: String = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if left_type not in ["int", "char"] or right_type not in ["int", "char"]:
		var msg: String = "Can't perform bitwise or on %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		# Need to return something
		expr.ret_type = left_type
		return left_type
	
	if left_type == "int" or right_type == "int":
		expr.left = Expr.Conversion.new(expr.left, "int", expr.op_token.line_num)
		expr.right = Expr.Conversion.new(expr.right, "int", expr.op_token.line_num)
		
		expr.ret_type = "int"
		return "int"
	
	expr.ret_type = "char"
	return "char"


func get_bit_xor_type(expr: Expr.Binary) -> String:
	var left_type: String = get_type(expr.left)
	var right_type: String = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if left_type not in ["int", "char"] or right_type not in ["int", "char"]:
		var msg: String = "Can't perform bitwise xor on %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		# Need to return something
		expr.ret_type = left_type
		return left_type
	
	if left_type == "int" or right_type == "int":
		expr.left = Expr.Conversion.new(expr.left, "int", expr.op_token.line_num)
		expr.right = Expr.Conversion.new(expr.right, "int", expr.op_token.line_num)
		
		expr.ret_type = "int"
		return "int"
	
	expr.ret_type = "char"
	return "char"


func get_and_type(expr: Expr.Binary) -> String:
	var left_type: String = get_type(expr.left)
	var right_type: String = get_type(expr.right)
	
	# If both inputs have the same type, that will be the return type
	if left_type == right_type:
		expr.ret_type = left_type
		return left_type
	
	# Otherwise, could be either type so we use mixed
	expr.ret_type = "mixed"
	return "mixed"


func get_or_type(expr: Expr.Binary) -> String:
	var left_type: String = get_type(expr.left)
	var right_type: String = get_type(expr.right)
	
	# If both inputs have the same type, that will be the return type
	if left_type == right_type:
		expr.ret_type = left_type
		return left_type
	
	# Otherwise, could be either type so we use mixed
	expr.ret_type = "mixed"
	return "mixed"


func get_xor_type(expr: Expr.Binary) -> String:
	# Type check inputs (Important that nested exprs are checked)
	get_type(expr.left)
	get_type(expr.right)
	
	# Convert inputs to bools
	expr.left = Expr.Conversion.new(expr.left, "bool", expr.op_token.line_num)
	expr.right = Expr.Conversion.new(expr.right, "bool", expr.op_token.line_num)
	
	# Otherwise, could be either type so we use mixed
	expr.ret_type = "bool"
	return "bool"


func get_nand_type(expr: Expr.Binary) -> String:
	# Type check inputs (Important that nested exprs are checked)
	get_type(expr.left)
	get_type(expr.right)
	
	# Convert inputs to bools
	expr.left = Expr.Conversion.new(expr.left, "bool", expr.op_token.line_num)
	expr.right = Expr.Conversion.new(expr.right, "bool", expr.op_token.line_num)
	
	# Otherwise, could be either type so we use mixed
	expr.ret_type = "bool"
	return "bool"


func get_nor_type(expr: Expr.Binary) -> String:
	# Type check inputs (Important that nested exprs are checked)
	get_type(expr.left)
	get_type(expr.right)
	
	# Convert inputs to bools
	expr.left = Expr.Conversion.new(expr.left, "bool", expr.op_token.line_num)
	expr.right = Expr.Conversion.new(expr.right, "bool", expr.op_token.line_num)
	
	# Otherwise, could be either type so we use mixed
	expr.ret_type = "bool"
	return "bool"


func get_xnor_type(expr: Expr.Binary) -> String:
	# Type check inputs (Important that nested exprs are checked)
	get_type(expr.left)
	get_type(expr.right)
	
	# Convert inputs to bools
	expr.left = Expr.Conversion.new(expr.left, "bool", expr.op_token.line_num)
	expr.right = Expr.Conversion.new(expr.right, "bool", expr.op_token.line_num)
	
	# Otherwise, could be either type so we use mixed
	expr.ret_type = "bool"
	return "bool"


func get_more_type(expr: Expr.Binary) -> String:
	var left_type: String = get_type(expr.left)
	var right_type: String = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if left_type not in ["int", "char", "float"] or right_type not in ["int", "char", "float"]:
		var msg: String = "Can't perform greater than on %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		expr.ret_type = "bool"
		return "bool"
	
	if left_type == "float" or right_type == "float":
		expr.left = Expr.Conversion.new(expr.left, "float", expr.op_token.line_num)
		expr.right = Expr.Conversion.new(expr.right, "float", expr.op_token.line_num)
		
		expr.ret_type = "bool"
		return "bool"
	
	if left_type == "int" or right_type == "int":
		expr.left = Expr.Conversion.new(expr.left, "int", expr.op_token.line_num)
		expr.right = Expr.Conversion.new(expr.right, "int", expr.op_token.line_num)
		
		expr.ret_type = "bool"
		return "bool"
	
	expr.ret_type = "bool"
	return "bool"


func get_more_equal_type(expr: Expr.Binary) -> String:
	var left_type: String = get_type(expr.left)
	var right_type: String = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if left_type not in ["int", "char", "float"] or right_type not in ["int", "char", "float"]:
		var types: Array[String] = [left_type, right_type]
		var msg: String = "Can't perform greater than or equal to on %s and %s" % types
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		expr.ret_type = "bool"
		return "bool"
	
	if left_type == "float" or right_type == "float":
		expr.left = Expr.Conversion.new(expr.left, "float", expr.op_token.line_num)
		expr.right = Expr.Conversion.new(expr.right, "float", expr.op_token.line_num)
		
		expr.ret_type = "bool"
		return "bool"
	
	if left_type == "int" or right_type == "int":
		expr.left = Expr.Conversion.new(expr.left, "int", expr.op_token.line_num)
		expr.right = Expr.Conversion.new(expr.right, "int", expr.op_token.line_num)
		
		expr.ret_type = "bool"
		return "bool"
	
	expr.ret_type = "bool"
	return "bool"


func get_less_type(expr: Expr.Binary) -> String:
	var left_type: String = get_type(expr.left)
	var right_type: String = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if left_type not in ["int", "char", "float"] or right_type not in ["int", "char", "float"]:
		var msg: String = "Can't perform less than on %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		expr.ret_type = "bool"
		return "bool"
	
	if left_type == "float" or right_type == "float":
		expr.left = Expr.Conversion.new(expr.left, "float", expr.op_token.line_num)
		expr.right = Expr.Conversion.new(expr.right, "float", expr.op_token.line_num)
		
		expr.ret_type = "bool"
		return "bool"
	
	if left_type == "int" or right_type == "int":
		expr.left = Expr.Conversion.new(expr.left, "int", expr.op_token.line_num)
		expr.right = Expr.Conversion.new(expr.right, "int", expr.op_token.line_num)
		
		expr.ret_type = "bool"
		return "bool"
	
	expr.ret_type = "bool"
	return "bool"


func get_less_equal_type(expr: Expr.Binary) -> String:
	var left_type: String = get_type(expr.left)
	var right_type: String = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if left_type not in ["int", "char", "float"] or right_type not in ["int", "char", "float"]:
		var types: Array[String] = [left_type, right_type]
		var msg: String = "Can't perform less than or equal to on %s and %s" % types
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		expr.ret_type = "bool"
		return "bool"
	
	if left_type == "float" or right_type == "float":
		expr.left = Expr.Conversion.new(expr.left, "float", expr.op_token.line_num)
		expr.right = Expr.Conversion.new(expr.right, "float", expr.op_token.line_num)
		
		expr.ret_type = "bool"
		return "bool"
	
	if left_type == "int" or right_type == "int":
		expr.left = Expr.Conversion.new(expr.left, "int", expr.op_token.line_num)
		expr.right = Expr.Conversion.new(expr.right, "int", expr.op_token.line_num)
		
		expr.ret_type = "bool"
		return "bool"
	
	expr.ret_type = "bool"
	return "bool"


func get_comp_equal_type(expr: Expr.Binary) -> String:
	var left_type: String = get_type(expr.left)
	var right_type: String = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if left_type not in ["int", "char", "float"] or right_type not in ["int", "char", "float"]:
		# Non-numbers must have matching types
		if left_type == right_type:
			expr.ret_type = "bool"
			return "bool"
		
		var msg: String = "Can't check equality of %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		expr.ret_type = "bool"
		return "bool"
	
	if left_type == "float" or right_type == "float":
		expr.left = Expr.Conversion.new(expr.left, "float", expr.op_token.line_num)
		expr.right = Expr.Conversion.new(expr.right, "float", expr.op_token.line_num)
		
		expr.ret_type = "bool"
		return "bool"
	
	if left_type == "int" or right_type == "int":
		expr.left = Expr.Conversion.new(expr.left, "int", expr.op_token.line_num)
		expr.right = Expr.Conversion.new(expr.right, "int", expr.op_token.line_num)
		
		expr.ret_type = "bool"
		return "bool"
	
	expr.ret_type = "bool"
	return "bool"


func get_not_equal_type(expr: Expr.Binary) -> String:
	var left_type: String = get_type(expr.left)
	var right_type: String = get_type(expr.right)
	
	# Check for invalid input. If the input type is bad, error out
	if left_type not in ["int", "char", "float"] or right_type not in ["int", "char", "float"]:
		# Non-numbers must have matching types
		if left_type == right_type:
			expr.ret_type = "bool"
			return "bool"
		
		var msg: String = "Can't check non-equality of %s and %s" % [left_type, right_type]
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		
		expr.ret_type = "bool"
		return "bool"
	
	if left_type == "float" or right_type == "float":
		expr.left = Expr.Conversion.new(expr.left, "float", expr.op_token.line_num)
		expr.right = Expr.Conversion.new(expr.right, "float", expr.op_token.line_num)
		
		expr.ret_type = "bool"
		return "bool"
	
	if left_type == "int" or right_type == "int":
		expr.left = Expr.Conversion.new(expr.left, "int", expr.op_token.line_num)
		expr.right = Expr.Conversion.new(expr.right, "int", expr.op_token.line_num)
		
		expr.ret_type = "bool"
		return "bool"
	
	expr.ret_type = "bool"
	return "bool"


func get_ternary_type(expr: Expr.Ternary) -> String:
	var left_type: String = get_type(expr.true_exp)
	var right_type: String = get_type(expr.false_exp)
	
	var cond_type: String = get_type(expr.cond)
	
	if cond_type != "bool":
		expr.cond = Expr.Conversion.new(expr.cond, "bool", expr.line_num)
	
	# If both inputs have the same type, that will be the return type
	if left_type == right_type:
		expr.ret_type = left_type
		return left_type
	
	# Otherwise, could be either type so we use mixed
	expr.ret_type = "mixed"
	return "mixed"
