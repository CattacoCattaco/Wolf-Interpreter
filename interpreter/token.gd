class_name Token
extends RefCounted
## Represents a meaningful unit of Wolf's grammar

## Contains all of the Various token types
enum {
	# Parentheses
	OPEN_PAREN, CLOSE_PAREN, OPEN_BRACE, CLOSE_BRACE, OPEN_BRACKET, CLOSE_BRACKET, # 0 - 5

	# Other one char tokens
	COMMA, DOT, COLON, BIT_NOT, NEW_LINE, # 6 - 10

	# Operators that change with an equal sign. Many also change with a second instance of self
	MINUS, MINUS_EQUAL, DECREMENT, # 11-13
	PLUS, PLUS_EQUAL, INCREMENT, # 14-16
	SLASH, SLASH_EQUAL, # 17 and 18
	STAR, STAR_EQUAL, EXPONENT, # 19-21
	PERCENT, PERCENT_EQUAL, # 22 and 23
	BIT_AND, BIT_AND_EQUAL, # 24 and 25
	BIT_OR, BIT_OR_EQUAL, # 26 and 27
	BIT_XOR, BIT_XOR_EQUAL, # 28 and 29
	NOT, NOT_EQUAL, # 30 and 31
	SET_EQUAL, COMP_EQUAL, # 32 and 33
	LESS, LESS_EQUAL, LEFT_SHIFT, # 34-36
	MORE, MORE_EQUAL, RIGHT_SHIFT, # 37-39

	# Literals and Identifiers
	LITERAL, # 40
	IDENTIFIER, # 41

	# Keywords
	AND, OR, XOR, # 42 - 44
	IF, ELIF, ELSE, # 45 - 47
	FOR, WHILE, # 48 and 49
	IN, RANGE, # 50 and 51
	CLASS, STRUCT, # 52 and 53
	IS, AS, # 54 and 55
	RETURN, # 56
	PRINT, # 57
	SUPER, # 58

	# We need to keep track of leading whitespace
	INDENT, # 59
	OUTDENT, # 60

	# End of file
	EOF, # 61
}

## Converts from keyword names to their respective token types
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

## This token's type
var token_type: int
## The characters that made this token
var lexeme: String
## The value of this token if it's a literal
var literal_value
## The type of this token if it's a literal
var literal_type: String
## The line number of this token
var line_num: int


func _init(p_token_type: int = 0, p_lexeme: String = "", p_literal_value = null, 
		p_literal_type: String = "", p_line_num: int = 0) -> void:
	token_type = p_token_type
	lexeme = p_lexeme
	literal_value = p_literal_value
	line_num = p_line_num


func _to_string() -> String:
	return "( %d %s %s %s )" % [token_type, lexeme, literal_type, literal_value]
