class_name Token
extends RefCounted

enum {
	# Parentheses
	OPEN_PAREN, CLOSE_PAREN, OPEN_BRACE, CLOSE_BRACE, OPEN_BRACKET, CLOSE_BRACKET, # 0 - 5

	# Other one char tokens
	COMMA, DOT, COLON, BIT_NOT, NEW_LINE, # 6 - 10

	# Operators that change with an equal sign. Many also change with a second instance of self
	MINUS, MINUS_EQUAL, DECREMENT, # 11-13
	PLUS, PLUS_EQUAL, INCREMENT, # 14-16
	SLASH, SLASH_EQUAL, # 17 and 18
	STAR, STAR_EQUAL, # 19 and 20
	PERCENT, PERCENT_EQUAL, # 21 and 22
	BIT_AND, BIT_AND_EQUAL, # 23 and 24
	BIT_OR, BIT_OR_EQUAL, # 25 and 26
	BIT_XOR, BIT_XOR_EQUAL, # 27 and 28
	NOT, NOT_EQUAL, # 29 and 30
	SET_EQUAL, COMP_EQUAL, # 31 and 32
	LESS, LESS_EQUAL, LEFT_SHIFT, # 33-35
	MORE, MORE_EQUAL, RIGHT_SHIFT, # 36-38

	# Literals and Identifiers
	LITERAL, # 39
	IDENTIFIER, # 40

	# Keywords
	AND, OR, XOR, # 41 - 43
	IF, ELIF, ELSE, # 44 - 46
	FOR, WHILE, # 47 and 48
	IN, RANGE, # 49 and 50
	CLASS, STRUCT, # 51 and 52
	IS, AS, # 53 and 54
	RETURN, # 55
	PRINT, # 56
	SUPER, # 57

	# We need to keep track of leading whitespace
	INDENT, # 58
	OUTDENT, # 59

	# End of file
	EOF, # 60
}

const KEYWORDS: Dictionary[String, int] = {
	"and": AND,
	"or": OR,
	"xor": XOR,
	"if": IF,
	"elif": ELIF,
	"else": ELSE,
	"for": FOR,
	"while": WHILE,
	"in": IN,
	"range": RANGE,
	"class": CLASS,
	"struct": STRUCT,
	"is": IS,
	"as": AS,
	"return": RETURN,
	"print": PRINT,
	"super": SUPER,
}

var token_type: int
var lexeme: String
var literal_value
var line_num: int


func _init(p_token_type: int = 0, p_lexeme: String = "", p_literal_value = null, 
		p_line_num: int = 0) -> void:
	token_type = p_token_type
	lexeme = p_lexeme
	literal_value = p_literal_value
	line_num = p_line_num


func _to_string() -> String:
	return "( %d %s %s )" % [token_type, lexeme, literal_value]
