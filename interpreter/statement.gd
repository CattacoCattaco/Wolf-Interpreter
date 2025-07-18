class_name Statement
extends RefCounted
## Represents a Wolf language statement

var line_start: int

class ExprStmt:
	extends Statement
	
	var expr: Expr
	
	func _init(p_line_start: int, p_expr: Expr) -> void:
		line_start = p_line_start
		expr = p_expr
	
	func _to_string() -> String:
		return str(expr)


class Print:
	extends Statement
	
	var expr: Expr
	
	func _init(p_line_start: int, p_expr: Expr) -> void:
		line_start = p_line_start
		expr = p_expr
	
	func _to_string() -> String:
		return "print(%s)" % expr


class Declaration:
	extends Statement
	
	var data_type: String
	var name: Token
	var initializer: Expr
	
	func _init(p_line_start: int, p_data_type: String, p_name: Token, p_initializer: Expr) -> void:
		line_start = p_line_start
		data_type = p_data_type
		name = p_name
		initializer = p_initializer
	
	func _to_string() -> String:
		var ret: String = "%s %s" % [data_type, name.lexeme]
		
		if initializer:
			ret += " = " + str(initializer)
		
		return ret
