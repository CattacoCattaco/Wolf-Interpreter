class_name Statement
extends RefCounted
## Represents a Wolf language statement

var line_start: int


class Empty:
	extends Statement
	
	func _init(p_line_start: int) -> void:
		line_start = p_line_start


class ExprStmt:
	extends Statement
	
	var expr: Expr
	
	func _init(p_line_start: int, p_expr: Expr) -> void:
		line_start = p_line_start
		expr = p_expr
	
	func _to_string() -> String:
		return str(expr)


class Declaration:
	extends Statement
	
	var data_type: WolfType
	var name: Token
	var initializer: Expr
	
	func _init(p_line_start: int, p_data_type: WolfType, p_name: Token, p_initializer: Expr) -> void:
		line_start = p_line_start
		data_type = p_data_type
		name = p_name
		initializer = p_initializer
	
	func _to_string() -> String:
		var ret: String = "%s %s" % [data_type, name.lexeme]
		
		if initializer:
			ret += " = " + str(initializer)
		
		return ret


class Block:
	extends Statement
	
	var statements: Array[Statement]
	var environment: WolfEnvironment
	
	func _init(p_line_start: int, p_statements: Array[Statement], 
			p_environment: WolfEnvironment) -> void:
		line_start = p_line_start
		statements = p_statements
		environment = p_environment
	
	func _to_string() -> String:
		var ret_text: String = ""
		
		for statement: Statement in statements:
			ret_text += str(statement) + "\n"
		
		ret_text = ret_text.indent("\t")
		
		return ret_text


class If:
	extends Statement
	
	var condition: Expr
	var block: Block
	
	var elif_conds: Array[Expr]
	var elif_blocks: Array[Block]
	var elif_lines: Array[int]
	
	var else_block: Block
	var else_line: int
	
	func _init(p_line_start: int, p_condition: Expr, p_block: Block, p_elif_conds: Array[Expr] = [], 
			p_elif_blocks: Array[Block] = [], p_elif_lines: Array[int] = [],
			p_else_block: Block = null, p_else_line: int = 0) -> void:
		line_start = p_line_start
		condition = p_condition
		block = p_block
		elif_conds = p_elif_conds
		elif_blocks = p_elif_blocks
		elif_lines = p_elif_lines
		else_block = p_else_block
		else_line = p_else_line
	
	func _to_string() -> String:
		var ret_text: String = "if %s:\n%s" % [condition, block]
		
		for i in len(elif_blocks):
			ret_text += "elif %s:\n%s" % [elif_conds[i], elif_blocks[i]]
		
		if else_block:
			ret_text += "else:\n%s" % else_block
		
		return ret_text


class While:
	extends Statement
	
	var condition: Expr
	var block: Block
	
	func _init(p_line_start: int, p_condition: Expr, p_block: Block) -> void:
		line_start = p_line_start
		condition = p_condition
		block = p_block
	
	func _to_string() -> String:
		return "while %s:\n%s" % [condition, block]


class ForRange:
	extends Statement
	
	var var_type: WolfType
	var var_name: String
	var start: Expr
	var end: Expr
	var step: Expr
	var block: Block
	
	func _init(p_line_start: int, p_var_type: WolfType, p_var_name: String, p_start: Expr,
			p_end: Expr, p_step: Expr, p_block: Block) -> void:
		line_start = p_line_start
		var_type = p_var_type
		var_name = p_var_name
		start = p_start
		end = p_end
		step = p_step
		block = p_block
	
	func _to_string() -> String:
		return "for %s %s in range(%s, %s, %s)\n%s" % [var_type, var_name, start, end, step, block]
