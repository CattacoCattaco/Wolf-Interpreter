class_name Evaluator
extends RefCounted

## A reference to the interpreter which created this
var interpreter: Interpreter


func evaluate_expr(expr: Expr) -> Dictionary:
	if expr is Expr.Literal:
		return eval_literal(expr)
	elif expr is Expr.Grouping:
		return eval_group(expr.grouped_expr)
	elif expr is Expr.Conversion:
		return eval_conversion(expr)
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


func eval_conversion(expr: Expr.Conversion) -> Dictionary:
	var unconverted_result = evaluate_expr(expr.converted_expr)
	
	var types: Array[String] = [unconverted_result["type"], expr.new_type]
	
	# Already the right type
	if types[0] == types[1]:
		return unconverted_result
	
	match types[1]:
		"string":
			return {
				"value": str(unconverted_result["value"]),
				"type": "string",
			}
		"int":
			if types[0] == "float":
				return {
					"value": unconverted_result["value"] as int,
					"type": "int",
				}
			elif types[0] == "char":
				return {
					"value": unconverted_result["value"].unicode_at(0) & 255,
					"type": "int",
				}
			elif types[0] == "bool":
				return {
					"value": 1 if unconverted_result["value"] else 0,
					"type": "int",
				}
		"char":
			if types[0] in ["int", "float"]:
				return {
					"value": char((unconverted_result["value"] as int) & 255),
					"type": "char",
				}
			elif types[0] == "bool":
				return {
					"value": char(1) if unconverted_result["value"] else char(0),
					"type": "char",
				}
		"float":
			if types[0] == "int":
				return {
					"value": unconverted_result["value"] as float,
					"type": "float",
				}
			elif types[0] == "char":
				return {
					"value": (unconverted_result["value"].unicode_at(0) & 255) as float,
					"type": "float",
				}
			elif types[0] == "bool":
				return {
					"value": 1.0 if unconverted_result["value"] else 0.0,
					"type": "float",
				}
		"bool":
			return {
				"value": is_truthy(unconverted_result["value"], types[0]),
				"type": "bool",
			}
	
	var msg: String = "Invalid type conversion from %s to %s" % types
	interpreter.error_handler.error(expr.line, msg)
	return {}


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
	
	if expr.ret_type == "char":
		return {
			"value": char((~value_to_negate["value"].unicode_at(0)) & 255),
			"type": "char"
		}
	
	return {
		"value": ~(value_to_negate["value"]),
		"type": expr.ret_type,
	}


func eval_not(expr: Expr.Unary) -> Dictionary:
	var value_to_negate: Dictionary = evaluate_expr(expr.right)
	return {
		"value": not value_to_negate["value"],
		"type": "bool",
	}


func eval_unary_minus(expr: Expr.Unary) -> Dictionary:
	var value_to_invert: Dictionary = evaluate_expr(expr.right)
	
	return {
		"value": -value_to_invert["value"],
		"type": expr.ret_type,
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
		Token.LEFT_SHIFT:
			return eval_left_shift(expr)
		Token.RIGHT_SHIFT:
			return eval_right_shift(expr)
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
		Token.EXPONENT:
			return eval_exponent(expr)
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
	
	var left: bool = left_value["value"]
	var right: bool = right_value["value"]
	
	var at_least_one: bool = left or right
	var both: bool = left and right
	
	return {
		"value": at_least_one and not both,
		"type": "bool",
	}


func eval_nand(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var left: bool = left_value["value"]
	var right: bool = right_value["value"]
	
	return {
		"value": not (left and right),
		"type": "bool",
	}


func eval_nor(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var left: bool = left_value["value"]
	var right: bool = right_value["value"]
	
	return {
		"value": not (left or right),
		"type": "bool",
	}


func eval_xnor(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var left: bool = left_value["value"]
	var right: bool = right_value["value"]
	
	var at_least_one: bool = left or right
	var both: bool = left and right
	
	return {
		"value": both or not at_least_one,
		"type": "bool",
	}


func eval_bit_and(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var result
	match expr.left.ret_type:
		"char":
			result = char(left_value["value"].unicode_at(0) & right_value["value"].unicode_at(0))
		"int":
			result = left_value["value"] & right_value["value"]
	
	return {
		"value": result,
		"type": expr.ret_type,
	}


func eval_bit_or(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var result
	match expr.left.ret_type:
		"char":
			result = char(left_value["value"].unicode_at(0) | right_value["value"].unicode_at(0))
		"int":
			result = left_value["value"] | right_value["value"]
	
	return {
		"value": result,
		"type": expr.ret_type,
	}


func eval_bit_xor(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var result
	match expr.left.ret_type:
		"char":
			result = char(left_value["value"].unicode_at(0) ^ right_value["value"].unicode_at(0))
		"int":
			result = left_value["value"] ^ right_value["value"]
	
	return {
		"value": result,
		"type": expr.ret_type,
	}


func eval_left_shift(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var result
	match expr.left.ret_type:
		"char":
			result = char(left_value["value"].unicode_at(0) << right_value["value"].unicode_at(0))
		"int":
			result = left_value["value"] << right_value["value"]
	
	return {
		"value": result,
		"type": expr.ret_type,
	}


func eval_right_shift(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var result
	match expr.left.ret_type:
		"char":
			result = char(left_value["value"].unicode_at(0) >> right_value["value"].unicode_at(0))
		"int":
			result = left_value["value"] >> right_value["value"]
	
	return {
		"value": result,
		"type": expr.ret_type,
	}


func eval_plus(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var result
	match expr.left.ret_type:
		"char":
			result = char(left_value["value"].unicode_at(0) + right_value["value"].unicode_at(0))
		"int":
			result = left_value["value"] + right_value["value"]
		"float":
			result = left_value["value"] + right_value["value"]
		"string":
			result = left_value["value"] + right_value["value"]
	
	return {
		"value": result,
		"type": expr.ret_type,
	}


func eval_binary_minus(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var result
	match expr.left.ret_type:
		"char":
			result = char(left_value["value"].unicode_at(0) - right_value["value"].unicode_at(0))
		"int":
			result = left_value["value"] - right_value["value"]
		"float":
			result = left_value["value"] - right_value["value"]
	
	return {
		"value": result,
		"type": expr.ret_type,
	}


func eval_multiply(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var result
	match expr.left.ret_type:
		"char":
			result = char(left_value["value"].unicode_at(0) * right_value["value"].unicode_at(0))
		"int":
			result = left_value["value"] * right_value["value"]
		"float":
			result = left_value["value"] * right_value["value"]
	
	return {
		"value": result,
		"type": expr.ret_type,
	}


func eval_divide(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var result
	match expr.left.ret_type:
		"char":
			result = char(left_value["value"].unicode_at(0) / right_value["value"].unicode_at(0))
		"int":
			result = left_value["value"] / right_value["value"]
		"float":
			result = left_value["value"] / right_value["value"]
	
	return {
		"value": result,
		"type": expr.ret_type,
	}


func eval_modulo(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var result
	match expr.left.ret_type:
		"char":
			result = char(left_value["value"].unicode_at(0) % right_value["value"].unicode_at(0))
		"int":
			result = posmod(left_value["value"], right_value["value"])
		"float":
			result = fposmod(left_value["value"], right_value["value"])
	
	return {
		"value": result,
		"type": expr.ret_type,
	}


func eval_exponent(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var result
	match expr.left.ret_type:
		"char":
			result = char(left_value["value"].unicode_at(0) ** right_value["value"].unicode_at(0))
		"int":
			result = left_value["value"] ** right_value["value"]
		"float":
			result = pow(left_value["value"], right_value["value"])
	
	return {
		"value": result,
		"type": expr.ret_type,
	}


func eval_more(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var result: bool
	match expr.left.ret_type:
		"char":
			result = left_value["value"].unicode_at(0) > right_value["value"].unicode_at(0)
		"int":
			result = left_value["value"] > right_value["value"]
		"float":
			result = left_value["value"] > right_value["value"]
	
	return {
		"value": result,
		"type": expr.ret_type,
	}


func eval_more_equal(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var result: bool
	match expr.left.ret_type:
		"char":
			result = left_value["value"].unicode_at(0) >= right_value["value"].unicode_at(0)
		"int":
			result = left_value["value"] >= right_value["value"]
		"float":
			result = left_value["value"] >= right_value["value"]
	
	return {
		"value": result,
		"type": expr.ret_type,
	}


func eval_less(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var result: bool
	match expr.left.ret_type:
		"char":
			result = left_value["value"].unicode_at(0) < right_value["value"].unicode_at(0)
		"int":
			result = left_value["value"] < right_value["value"]
		"float":
			result = left_value["value"] < right_value["value"]
	
	return {
		"value": result,
		"type": expr.ret_type,
	}


func eval_less_equal(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var result: bool
	match expr.left.ret_type:
		"char":
			result = left_value["value"].unicode_at(0) <= right_value["value"].unicode_at(0)
		"int":
			result = left_value["value"] <= right_value["value"]
		"float":
			result = left_value["value"] <= right_value["value"]
	
	return {
		"value": result,
		"type": expr.ret_type,
	}


func eval_comp_equal(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var result: bool
	match expr.left.ret_type:
		"char":
			result = left_value["value"].unicode_at(0) == right_value["value"].unicode_at(0)
		"int":
			result = left_value["value"] == right_value["value"]
		"float":
			result = left_value["value"] == right_value["value"]
		"string":
			result = left_value["value"] == right_value["value"]
		"bool":
			result = left_value["value"] == right_value["value"]
		"null":
			result = true
	
	return {
		"value": result,
		"type": expr.ret_type,
	}


func eval_not_equal(expr: Expr.Binary) -> Dictionary:
	var left_value: Dictionary = evaluate_expr(expr.left)
	var right_value: Dictionary = evaluate_expr(expr.right)
	
	var result: bool
	match expr.left.ret_type:
		"char":
			result = left_value["value"].unicode_at(0) != right_value["value"].unicode_at(0)
		"int":
			result = left_value["value"] != right_value["value"]
		"float":
			result = left_value["value"] != right_value["value"]
		"string":
			result = left_value["value"] != right_value["value"]
		"bool":
			result = left_value["value"] != right_value["value"]
		"null":
			result = false
	
	return {
		"value": result,
		"type": expr.ret_type,
	}


func eval_ternary(expr: Expr.Ternary) -> Dictionary:
	var cond_eval: Dictionary = evaluate_expr(expr.cond)
	var cond_met: bool = cond_eval["value"]
	
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
			return value.unicode_at(0) == 0
		"null":
			return false
		_:
			return true
