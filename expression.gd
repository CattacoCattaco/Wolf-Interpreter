class_name Expr
extends RefCounted
## Represents a Wolf language expression

var ret_type: String


## Represents an expression using the ternary operator: a if cond else b
class Ternary:
	extends Expr
	
	## The expression if cond is true
	var true_exp: Expr
	## The condition
	var cond: Expr
	## The expression if cond is false
	var false_exp: Expr
	
	## The line number
	var line_num
	
	func _init(p_true_exp: Expr, p_cond: Expr, p_false_exp: Expr, p_line_num: int) -> void:
		true_exp = p_true_exp
		cond = p_cond
		false_exp = p_false_exp
		line_num = p_line_num
	
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


## Represents an expression which has had its type converted: expression as type
class Conversion:
	extends Expr
	
	## The expression which was type converted
	var converted_expr: Expr
	## The type which is being converted to
	var new_type: String
	## The line number of the as token
	var line: int
	
	func _init(p_converted_expr: Expr, p_new_type: String, p_line: int) -> void:
		converted_expr = p_converted_expr
		new_type = p_new_type
		line = p_line
		
		ret_type = new_type
	
	func _to_string() -> String:
		return "(%s as %s)" % [converted_expr, new_type]


## Represents a grouped expression: (expression)
class Grouping:
	extends Expr
	
	## The expression which was grouped
	var grouped_expr: Expr
	
	func _init(p_grouped_expr: Expr) -> void:
		grouped_expr = p_grouped_expr
	
	func _to_string() -> String:
		return "(%s)" % grouped_expr


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
