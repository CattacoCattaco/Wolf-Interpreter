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
	STAR, STAR_EQUAL, EXPONENT, EXPONENT_EQUAL, # 19-22
	PERCENT, PERCENT_EQUAL, # 23 and 24
	BIT_AND, BIT_AND_EQUAL, # 24 and 26
	BIT_OR, BIT_OR_EQUAL, # 27 and 28
	BIT_XOR, BIT_XOR_EQUAL, # 29 and 30
	NOT, NOT_EQUAL, # 31 and 32
	SET_EQUAL, COMP_EQUAL, # 33 and 34
	LESS, LESS_EQUAL, LEFT_SHIFT, LEFT_SHIFT_EQUAL, # 35-38
	MORE, MORE_EQUAL, RIGHT_SHIFT, RIGHT_SHIFT_EQUAL, # 39-42

	# Literals, identifiers, and types
	LITERAL, # 43
	IDENTIFIER, # 44
	DATA_TYPE, # 45

	# Keywords
	AND, OR, XOR, # 46 - 48
	NAND, NOR, XNOR, # 49 - 51
	IF, ELIF, ELSE, # 52 - 54
	FOR, WHILE, # 55 and 56
	IN, RANGE, # 57 and 58
	CLASS, STRUCT, # 59 and 60
	IS, AS, # 61 and 62
	RETURN, # 63
	PRINT, # 64
	SUPER, # 65

	# We need to keep track of leading whitespace
	INDENT, # 66
	OUTDENT, # 67

	# End of file
	EOF, # 68
}

## Converts from keyword names to their respective token types
const KEYWORDS: Dictionary[String, int] = {
	"and": AND,
	"or": OR,
	"xor": XOR,
	"nand": NAND,
	"nor": NOR,
	"xnor": XNOR,
	"not": NOT,
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
## The type of this token if it's a literal, always lower case
var literal_type: String
## The line number of this token
var line_num: int


func _init(p_token_type: int = 0, p_lexeme: String = "", p_literal_value = null, 
		p_literal_type: String = "", p_line_num: int = 0) -> void:
	token_type = p_token_type
	lexeme = p_lexeme
	literal_value = p_literal_value
	literal_type = p_literal_type
	line_num = p_line_num


func _to_string() -> String:
	return "( %d %s %s %s )" % [token_type, lexeme, literal_value, literal_type]
