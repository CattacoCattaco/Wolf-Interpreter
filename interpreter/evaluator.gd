class_name Evaluator
extends RefCounted

## A reference to the interpreter which created this
var interpreter: Interpreter


func evaluate_expr(expr: Expr) -> Dictionary:
	if expr is Expr.Literal:
		return eval_literal(expr)
	elif expr is Expr.Grouping:
		return eval_group(expr.grouped_expr)
	elif expr is Expr.Unary:
		return eval_unary(expr)
	elif expr is Expr.Binary:
		return eval_binary(expr)
	elif expr is Expr.Ternary:
		return eval_ternary(expr)
	
	return {}


func eval_literal(expr: Expr.Literal) -> Dictionary:
	return {
			"value": expr.literal_token.literal_value,
			"type": expr.literal_token.literal_type,
		}


func eval_group(expr: Expr.Grouping) -> Dictionary:
	return evaluate_expr(expr.grouped_expr)


func eval_unary(expr: Expr.Unary) -> Dictionary:
	match expr.op_token.token_type:
		Token.BIT_NOT:
			return eval_bit_not(expr)
		Token.NOT:
			return eval_not(expr)
		Token.MINUS:
			return eval_unary_minus(expr)
	
	return {}


func eval_bit_not(expr: Expr.Unary) -> Dictionary:
	var value_to_negate: Dictionary = evaluate_expr(expr.right)
	# Only ints and floats can be bit notted
	match value_to_negate["type"]:
		"int":
			pass
		"float":
			pass
		_:
			var msg: String = "Can not perform bitwise not on non-numerical value"
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return value_to_negate
	
	return {
		"value": ~value_to_negate["value"],
		"type": value_to_negate["type"],
	}


func eval_not(expr: Expr.Unary) -> Dictionary:
	var value_to_negate: Dictionary = evaluate_expr(expr.right)
	return {
		"value": not is_truthy(value_to_negate["value"], value_to_negate["type"]),
		"type": value_to_negate["type"],
	}


func eval_unary_minus(expr: Expr.Unary) -> Dictionary:
	var value_to_invert: Dictionary = evaluate_expr(expr.right)
	# Only ints and floats can have unary - done on them
	match value_to_invert["type"]:
		"int":
			pass
		"float":
			pass
		_:
			var msg: String = "Can not perform unary - on non-numerical value"
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return value_to_invert
	
	return {
		"value": -value_to_invert["value"],
		"type": value_to_invert["type"],
	}


func eval_binary(expr: Expr.Binary) -> Dictionary:
	match expr.op_token.token_type:
		Token.AND:
			return eval_and(expr)
		Token.OR:
			return eval_or(expr)
		Token.XOR:
			return eval_xor(expr)
		Token.NAND:
			return eval_nand(expr)
		Token.NOR:
			return eval_nor(expr)
		Token.XNOR:
			return eval_xnor(expr)
		Token.BIT_AND:
			return eval_bit_and(expr)
		Token.BIT_OR:
			return eval_bit_or(expr)
		Token.BIT_XOR:
			return eval_bit_xor(expr)
		Token.PLUS:
			return eval_plus(expr)
		Token.MINUS:
			return eval_binary_minus(expr)
		Token.STAR:
			return eval_multiply(expr)
		Token.SLASH:
			return eval_divide(expr)
		Token.PERCENT:
			return eval_modulo(expr)
		Token.MORE:
			return eval_more(expr)
		Token.MORE_EQUAL:
			return eval_more_equal(expr)
		Token.LESS:
			return eval_less(expr)
		Token.LESS_EQUAL:
			return eval_less_equal(expr)
		Token.COMP_EQUAL:
			return eval_comp_equal(expr)
		Token.NOT_EQUAL:
			return eval_not_equal(expr)
	
	return {}


func eval_and(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	if is_truthy(left_value["value"], left_value["type"]):
		return right_value
	else:
		return left_value


func eval_or(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	if is_truthy(left_value["value"], left_value["type"]):
		return left_value
	else:
		return right_value


func eval_xor(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var left_truthy: bool = is_truthy(left_value["value"], left_value["type"])
	var right_truthy: bool = is_truthy(right_value["value"], right_value["type"])
	
	var at_least_one: bool = left_truthy or right_truthy
	var both: bool = left_truthy and right_truthy
	
	return {
		"value": at_least_one and not both,
		"type": "bool",
	}


func eval_nand(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var left_truthy: bool = is_truthy(left_value["value"], left_value["type"])
	var right_truthy: bool = is_truthy(right_value["value"], right_value["type"])
	
	return {
		"value": not (left_truthy and right_truthy),
		"type": "bool",
	}


func eval_nor(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var left_truthy: bool = is_truthy(left_value["value"], left_value["type"])
	var right_truthy: bool = is_truthy(right_value["value"], right_value["type"])
	
	return {
		"value": not (left_truthy or right_truthy),
		"type": "bool",
	}


func eval_xnor(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var left_truthy: bool = is_truthy(left_value["value"], left_value["type"])
	var right_truthy: bool = is_truthy(right_value["value"], right_value["type"])
	
	var at_least_one: bool = left_truthy or right_truthy
	var both: bool = left_truthy and right_truthy
	
	return {
		"value": both or not at_least_one,
		"type": "bool",
	}


func eval_bit_and(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var type: String
	# Only nums can be bit anded
	match left_value["type"]:
		"int":
			# Assume the result will be an int for now
			type = "int"
		"float":
			# Result should be float
			type = "float"
		"char":
			# Convert value to int and assume the result will be an int for now
			left_value["value"] = left_value["value"].unicode_at(0)
			type = "int"
		_:
			var msg: String = "Can not perform bitwise and on non-numerical value"
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	match right_value["type"]:
		"int":
			# Use type of left
			pass
		"float":
			# Result should be float
			type = "float"
		"char":
			# Convert value to int and use type of left
			left_value["value"] = left_value["value"].unicode_at(0)
		_:
			var msg: String = "Can not perform bitwise and on non-numerical value"
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	return {
		"value": left_value["value"] & right_value["value"],
		"type": type,
	}


func eval_bit_or(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var type: String
	# Only nums can be bit orred
	match left_value["type"]:
		"int":
			# Assume the result will be an int for now
			type = "int"
		"float":
			# Result should be float
			type = "float"
		"char":
			# Convert value to int and assume the result will be an int for now
			left_value["value"] = left_value["value"].unicode_at(0)
			type = "int"
		_:
			var msg: String = "Can not perform bitwise or on non-numerical value"
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	match right_value["type"]:
		"int":
			# Use type of left
			pass
		"float":
			# Result should be float
			type = "float"
		"char":
			# Convert value to int and use type of left
			left_value["value"] = left_value["value"].unicode_at(0)
		_:
			var msg: String = "Can not perform bitwise or on non-numerical value"
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	return {
		"value": left_value["value"] | right_value["value"],
		"type": type,
	}


func eval_bit_xor(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var type: String
	# Only nums can be bit xorred
	match left_value["type"]:
		"int":
			# Assume the result will be an int for now
			type = "int"
		"float":
			# Result should be float
			type = "float"
		"char":
			# Convert value to int and assume the result will be an int for now
			left_value["value"] = left_value["value"].unicode_at(0)
			type = "int"
		_:
			var msg: String = "Can not perform bitwise xor on non-numerical value"
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	match right_value["type"]:
		"int":
			# Use type of left
			pass
		"float":
			# Result should be float
			type = "float"
		"char":
			# Convert value to int and use type of left
			left_value["value"] = left_value["value"].unicode_at(0)
		_:
			var msg: String = "Can not perform bitwise xor on non-numerical value"
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	return {
		"value": left_value["value"] ^ right_value["value"],
		"type": type,
	}


func eval_plus(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var type: String
	# Only nums can be added and strings can be concatinated
	match left_value["type"]:
		"int":
			# Assume the result will be an int for now
			type = "int"
		"float":
			# Result should be float
			type = "float"
		"char":
			# Convert value to int and assume the result will be an int for now
			left_value["value"] = left_value["value"].unicode_at(0)
			type = "int"
		"string":
			# Concatination
			type = "string"
		_:
			var msg: String = "Can not perform + on non-numerical, non-string value"
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	match right_value["type"]:
		"int":
			# Use type of left but it better not be a string
			if type == "string":
				var msg: String = "Can not perform additon on int and string"
				interpreter.error_handler.error(expr.op_token.line_num, msg)
				return left_value
		"float":
			# Result should be float but left shouldn't be a string
			type = "float"
			
			if type == "string":
				var msg: String = "Can not perform additon on float and string"
				interpreter.error_handler.error(expr.op_token.line_num, msg)
				return left_value
		"char":
			# Convert value to int and use type of right unless it's a string
			if type == "string":
				var msg: String = "Can not perform additon on int and string"
				interpreter.error_handler.error(expr.op_token.line_num, msg)
				return left_value
			left_value["value"] = left_value["value"].unicode_at(0)
		"string":
			if type != "string":
				var msg: String = "Can not perform additon on %s and string" % type
				interpreter.error_handler.error(expr.op_token.line_num, msg)
				return left_value
		_:
			var msg: String = "Can not perform + on non-numerical, non-string value"
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	return {
		"value": left_value["value"] + right_value["value"],
		"type": type,
	}


func eval_binary_minus(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var type: String
	# Only nums can be subtracted
	match left_value["type"]:
		"int":
			# Assume the result will be an int for now
			type = "int"
		"float":
			# Result should be float
			type = "float"
		"char":
			# Convert value to int and assume the result will be an int for now
			left_value["value"] = left_value["value"].unicode_at(0)
			type = "int"
		_:
			var msg: String = "Can not perform subtraction on non-numerical value"
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	match right_value["type"]:
		"int":
			# Use type of left
			pass
		"float":
			# Result should be float
			type = "float"
		"char":
			# Convert value to int and use type of left
			left_value["value"] = left_value["value"].unicode_at(0)
		_:
			var msg: String = "Can not perform subtraction on non-numerical value"
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	return {
		"value": left_value["value"] - right_value["value"],
		"type": type,
	}


func eval_multiply(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var type: String
	# Only nums can be multiplied
	match left_value["type"]:
		"int":
			# Assume the result will be an int for now
			type = "int"
		"float":
			# Result should be float
			type = "float"
		"char":
			# Convert value to int and assume the result will be an int for now
			left_value["value"] = left_value["value"].unicode_at(0)
			type = "int"
		_:
			var msg: String = "Can not perform multiplication on non-numerical value"
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	match right_value["type"]:
		"int":
			# Use type of left
			pass
		"float":
			# Result should be float
			type = "float"
		"char":
			# Convert value to int and use type of left
			left_value["value"] = left_value["value"].unicode_at(0)
			type = "int"
		_:
			var msg: String = "Can not perform multiplication on non-numerical value"
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	return {
		"value": left_value["value"] * right_value["value"],
		"type": type,
	}


func eval_divide(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var type: String
	# Only nums can be divided
	match left_value["type"]:
		"int":
			# Assume the result will be an int for now
			type = "int"
		"float":
			# Result should be float
			type = "float"
		"char":
			# Convert value to int and assume the result will be an int for now
			left_value["value"] = left_value["value"].unicode_at(0)
			type = "int"
		_:
			var msg: String = "Can not perform division on non-numerical value"
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	match right_value["type"]:
		"int":
			# Use type of left
			pass
		"float":
			# Result should be float
			type = "float"
		"char":
			# Convert value to int and use type of left
			left_value["value"] = left_value["value"].unicode_at(0)
		_:
			var msg: String = "Can not perform division on non-numerical value"
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	return {
		"value": left_value["value"] / right_value["value"],
		"type": type,
	}


func eval_modulo(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var type: String
	# Only nums can have modulo done on them
	match left_value["type"]:
		"int":
			# Assume the result will be an int for now
			type = "int"
		"float":
			# Result should be float
			type = "float"
		"char":
			# Convert value to int and assume the result will be an int for now
			left_value["value"] = left_value["value"].unicode_at(0)
			type = "int"
		_:
			var msg: String = "Can not perform modulo on non-numerical value"
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	match right_value["type"]:
		"int":
			# Use type of left
			pass
		"float":
			# Result should be float
			type = "float"
		"char":
			# Convert value to int and use type of left
			left_value["value"] = left_value["value"].unicode_at(0)
			type = "int"
		_:
			var msg: String = "Can not perform modulo on non-numerical value"
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	return {
		"value": fposmod(left_value["value"], right_value["value"]),
		"type": type,
	}


func eval_more(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	# Only nums can be compared with >
	match left_value["type"]:
		"int":
			pass
		"float":
			pass
		"char":
			# Convert value to int
			left_value["value"] = left_value["value"].unicode_at(0)
		_:
			var msg: String = "Can not do > comparison on non-numerical values"
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	match right_value["type"]:
		"int":
			# Use type of left
			pass
		"float":
			pass
		"char":
			# Convert value to int
			left_value["value"] = left_value["value"].unicode_at(0)
		_:
			var msg: String = "Can not do > comparison on non-numerical values"
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	return {
		"value": left_value["value"] > right_value["value"],
		"type": "bool",
	}


func eval_more_equal(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	# Only nums can be compared with >
	match left_value["type"]:
		"int":
			pass
		"float":
			pass
		"char":
			# Convert value to int
			left_value["value"] = left_value["value"].unicode_at(0)
		_:
			var msg: String = "Can not do > comparison on non-numerical values"
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	match right_value["type"]:
		"int":
			# Use type of left
			pass
		"float":
			pass
		"char":
			# Convert value to int
			left_value["value"] = left_value["value"].unicode_at(0)
		_:
			var msg: String = "Can not do > comparison on non-numerical values"
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	return {
		"value": left_value["value"] >= right_value["value"],
		"type": "bool",
	}


func eval_less(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	# Only nums can be compared with >
	match left_value["type"]:
		"int":
			pass
		"float":
			pass
		"char":
			# Convert value to int
			left_value["value"] = left_value["value"].unicode_at(0)
		_:
			var msg: String = "Can not do > comparison on non-numerical values"
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	match right_value["type"]:
		"int":
			# Use type of left
			pass
		"float":
			pass
		"char":
			# Convert value to int
			left_value["value"] = left_value["value"].unicode_at(0)
		_:
			var msg: String = "Can not do > comparison on non-numerical values"
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	return {
		"value": left_value["value"] < right_value["value"],
		"type": "bool",
	}


func eval_less_equal(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	# Only nums can be compared with >
	match left_value["type"]:
		"int":
			pass
		"float":
			pass
		"char":
			# Convert value to int
			left_value["value"] = left_value["value"].unicode_at(0)
		_:
			var msg: String = "Can not do > comparison on non-numerical values"
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	match right_value["type"]:
		"int":
			# Use type of left
			pass
		"float":
			pass
		"char":
			# Convert value to int
			left_value["value"] = left_value["value"].unicode_at(0)
		_:
			var msg: String = "Can not do > comparison on non-numerical values"
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	return {
		"value": left_value["value"] <= right_value["value"],
		"type": "bool",
	}


func eval_comp_equal(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var new_left: Dictionary
	var new_right: Dictionary
	
	# Only ints and floats can be compared with >
	match left_value["type"]:
		"int":
			# Convert all nums to floats for comparison
			new_left = {
				"value": left_value["value"] as float,
				"type": "float",
			}
		"char":
			# Convert all nums to floats for comparison
			new_left = {
				"value": left_value["value"].unicode_at(0) as int as float,
				"type": "float",
			}
		"float":
			# No conversion needed
			new_left = left_value
		"string":
			# No conversion needed
			new_left = left_value
		"bool":
			# No conversion needed
			new_left = left_value
		"null":
			# No conversion needed
			new_left = left_value
		_:
			var msg: String = "Unknown type in == comparison: " % left_value["type"]
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	match right_value["type"]:
		"int":
			# Convert all nums to floats for comparison
			new_right = {
				"value": right_value["value"] as float,
				"type": "float",
			}
		"char":
			# Convert all nums to floats for comparison
			new_right = {
				"value": right_value["value"].unicode_at(0) as float,
				"type": "float",
			}
		"float":
			# No conversion needed
			new_right = right_value
		"string":
			# No conversion needed
			new_right = right_value
		"bool":
			# No conversion needed
			new_right = right_value
		"null":
			# No conversion needed
			new_right = right_value
		_:
			var msg: String = "Unknown type in == comparison: " % left_value["type"]
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	if new_left["type"] != new_right["type"]:
		var msg: String = "Equals comparison type mismatch"
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		return left_value
	
	return {
		"value": left_value["value"] == right_value["value"],
		"type": "bool",
	}


func eval_not_equal(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var new_left: Dictionary
	var new_right: Dictionary
	
	# Only ints and floats can be compared with >
	match left_value["type"]:
		"int":
			# Convert all nums to floats for comparison
			new_left = {
				"value": left_value["value"] as float,
				"type": "float",
			}
		"char":
			# Convert all nums to floats for comparison
			new_left = {
				"value": left_value["value"].unicode_at(0) as int as float,
				"type": "float",
			}
		"float":
			# No conversion needed
			new_left = left_value
		"string":
			# No conversion needed
			new_left = left_value
		"bool":
			# No conversion needed
			new_left = left_value
		"null":
			# No conversion needed
			new_left = left_value
		_:
			var msg: String = "Unknown type in != comparison: " % left_value["type"]
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	match right_value["type"]:
		"int":
			# Convert all nums to floats for comparison
			new_right = {
				"value": right_value["value"] as float,
				"type": "float",
			}
		"char":
			# Convert all nums to floats for comparison
			new_right = {
				"value": right_value["value"].unicode_at(0) as float,
				"type": "float",
			}
		"float":
			# No conversion needed
			new_right = right_value
		"string":
			# No conversion needed
			new_right = right_value
		"bool":
			# No conversion needed
			new_right = right_value
		"null":
			# No conversion needed
			new_right = right_value
		_:
			var msg: String = "Unknown type in != comparison: " % left_value["type"]
			interpreter.error_handler.error(expr.op_token.line_num, msg)
			return left_value
	
	if new_left["type"] != new_right["type"]:
		var msg: String = "Not equal comparison type mismatch"
		interpreter.error_handler.error(expr.op_token.line_num, msg)
		return left_value
	
	return {
		"value": left_value["value"] != right_value["value"],
		"type": "bool",
	}


func eval_ternary(expr: Expr.Ternary) -> Dictionary:
	var cond_eval: Dictionary = evaluate_expr(expr.cond)
	var cond_met: bool = is_truthy(cond_eval["value"], cond_eval["type"])
	
	var true_value: Dictionary = evaluate_expr(expr.true_exp)
	var false_value: Dictionary = evaluate_expr(expr.false_exp)
	
	return true_value if cond_met else false_value


func is_truthy(value, type: String) -> bool:
	match type:
		"bool":
			return value
		"int":
			return value != 0
		"float":
			return value != 0
		"string":
			return value != ""
		"char":
			return false
		"null":
			return false
		_:
			return true
