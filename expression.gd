class_name Expr
extends RefCounted
## Represents a Wolf language expression


## Represents an expression using the ternary operator: a if cond else b
class Ternary:
	extends Expr
	
	## The expression if cond is true
	var true_exp: Expr
	## The condition
	var cond: Expr
	## The expression if cond is false
	var false_exp: Expr
	
	func _init(p_true_exp: Expr, p_cond: Expr, p_false_exp: Expr) -> void:
		true_exp = p_true_exp
		cond = p_cond
		false_exp = p_false_exp
	
	func _to_string() -> String:
		return "(%s if %s else %s)" % [true_exp, cond, false_exp]


## Represents any binary expression: left operator right
class Binary:
	extends Expr
	
	## The expression to the left of the operator
	var left: Expr
	## The operator
	var op_token: Token
	## The expression to the right of the operator
	var right: Expr
	
	func _init(p_left: Expr, p_op_token: Token, p_right: Expr) -> void:
		left = p_left
		op_token = p_op_token
		right = p_right
	
	func _to_string() -> String:
		return "(%s %s %s)" % [left, op_token.lexeme, right]


## Represents any unary expression: operator right
class Unary:
	extends Expr
	
	## The operator
	var op_token: Token
	## The expression to the right of the operator
	var right: Expr
	
	func _init(p_op_token: Token, p_right: Expr) -> void:
		op_token = p_op_token
		right = p_right
	
	func _to_string() -> String:
		return "(%s %s)" % [op_token.lexeme, right]


## Represents a grouped expression: (expression)
class Grouping:
	extends Expr
	
	## The expression which was grouped
	var expr: Expr
	
	func _init(p_expr: Expr) -> void:
		expr = p_expr
	
	func _to_string() -> String:
		return "(%s)" % expr


## Represents a literal: a string, char, bool, int, float, or null
class Literal:
	extends Expr
	
	## The literal token which is being represented
	var literal_token: Token
	
	func _init(p_literal_token: Token) -> void:
		literal_token = p_literal_token
	
	func _to_string() -> String:
		# Strings and chars need double or single quotes surrounding them
		if literal_token.literal_type == "string":
			return "\"%s\"" % literal_token.literal_value
		elif literal_token.literal_type == "char":
			return "'%s'" % literal_token.literal_value
		
		return "%s" % literal_token.literal_value
