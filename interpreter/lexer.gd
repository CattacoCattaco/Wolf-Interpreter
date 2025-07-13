class_name Lexer
extends RefCounted
## Turns the source code into an array of tokens

## Source code being read
var source: String
## The tokens being outputted
var tokens: Array[Token]

## The position of the start of the current token
var start: int = 0
## The position of the char which is currently being read
var current: int = 0
## The current line number we are on
var line: int = 1

## Is this the start of a line?
var line_start: bool = true
## The leading white space of the previous line
var last_line_white_space: String = ""

## What layer of parentheses/brackets/curly braces are we in?
var paren_layer: int = 0

## Checks if a string has a digit
var digit_regex := RegEx.create_from_string("[0-9]")
## Checks if a string has a letter
var alpha_regex := RegEx.create_from_string("[A-Za-z]")

## A reference to the interpreter which created this
var interpreter: Interpreter


func _init(code: String) -> void:
	source = code


## Are we at the end of the code?
func _is_at_end() -> bool:
	return current >= len(source) - 1


## Move forwards in the code and return the new current char
func _advance() -> String:
	var ret_value: String = source[current] if not _is_at_end() else ""
	
	current += 1
	
	return ret_value


## Returns the next char without advancing
func _peek() -> String:
	return source[current] if not _is_at_end() else ""


## Add a token to tokens
func _add_token(token_type: int, literal_value = null, literal_type: String = "") -> void:
	var text: String = source.substr(start, current - start)
	tokens.append(Token.new(token_type, text, literal_value, literal_type, line))


## Is the inputted string a single digit?
func _is_digit(character: String) -> bool:
	return len(character) == 1 and digit_regex.search(character)


## Is the inputted string a single letter?
func _is_alpha(character: String) -> bool:
	return len(character) == 1 and alpha_regex.search(character)


## Is the inputted string a single alphanumeric character?
func _is_alphanumeric(character: String) -> bool:
	return len(character) == 1 and (digit_regex.search(character) or alpha_regex.search(character))


## If this is the start of a line and the previous line didn't have whitespace, outdent
func _check_no_lead_white_space() -> void:
	if line_start and paren_layer == 0:
		if len(last_line_white_space) > 0:
			_add_token(Token.OUTDENT)
		
		line_start = false


## Finds the next token and adds it
func _scan_token() -> void:
	var c: String = _advance()
	
	match c:
		"(":
			# Opening paren character, simple one char token but needs to increase paren_layer
			_check_no_lead_white_space()
			_add_token(Token.OPEN_PAREN)
			
			paren_layer += 1
		")":
			# Closing paren character, simple one char token but needs to decrease paren_layer
			_check_no_lead_white_space()
			_add_token(Token.CLOSE_PAREN)
			
			paren_layer -= 1
			# The paren layer being negative would indicate that there was no opening paren
			if paren_layer < 0:
				interpreter.error_handler.error(line, "Unexpected closing paren ')'")
		"[":
			# Opening paren character, simple one char token but needs to increase paren_layer
			_check_no_lead_white_space()
			_add_token(Token.OPEN_BRACKET)
			
			paren_layer += 1
		"]":
			# Closing paren character, simple one char token but needs to decrease paren_layer
			_check_no_lead_white_space()
			_add_token(Token.CLOSE_BRACKET)
			
			paren_layer -= 1
			# The paren layer being negative would indicate that there was no opening paren
			if paren_layer < 0:
				interpreter.error_handler.error(line, "Unexpected closing paren ']'")
		"{":
			# Opening paren character, simple one char token but needs to increase paren_layer
			_check_no_lead_white_space()
			_add_token(Token.OPEN_BRACE)
			
			paren_layer += 1
		"}":
			# Closing paren character, simple one char token but needs to decrease paren_layer
			_check_no_lead_white_space()
			_add_token(Token.CLOSE_BRACE)
			
			paren_layer -= 1
			# The paren layer being negative would indicate that there was no opening paren
			if paren_layer < 0:
				interpreter.error_handler.error(line, "Unexpected closing paren '}'")
		",":
			# Simple one char token
			_check_no_lead_white_space()
			_add_token(Token.COMMA)
		".":
			# Simple one char token
			_check_no_lead_white_space()
			_add_token(Token.DOT)
		":":
			# Simple one char token
			_check_no_lead_white_space()
			_add_token(Token.COLON)
		"~":
			# Simple one char token
			_check_no_lead_white_space()
			_add_token(Token.BIT_NOT)
		"-":
			# Sometimes a one char token, sometimes two
			# If followed by self or '=', has a different meaning
			_check_no_lead_white_space()
			
			var next: String = _peek()
			if next == "=":
				_advance()
				_add_token(Token.MINUS_EQUAL)
			elif next == "-":
				_advance()
				_add_token(Token.DECREMENT)
			else:
				_add_token(Token.MINUS)
		"+":
			# Sometimes a one char token, sometimes two
			# If followed by self or '=', has a different meaning
			_check_no_lead_white_space()
			
			var next: String = _peek()
			if next == "=":
				_advance()
				_add_token(Token.PLUS_EQUAL)
			elif next == "+":
				_advance()
				_add_token(Token.INCREMENT)
			else:
				_add_token(Token.PLUS)
		"/":
			# Sometimes a one char token, sometimes two
			# If followed by '=', has a different meaning
			_check_no_lead_white_space()
			
			var next: String = _peek()
			if next == "=":
				_advance()
				_add_token(Token.SLASH_EQUAL)
			else:
				_add_token(Token.SLASH)
		"*":
			# Sometimes a one char token, sometimes two
			# If followed by self or '=', has a different meaning
			_check_no_lead_white_space()
			
			var next: String = _peek()
			if next == "=":
				_advance()
				_add_token(Token.STAR_EQUAL)
			elif next == "*":
				_advance()
				_add_token(Token.EXPONENT)
			else:
				_add_token(Token.STAR)
		"%":
			# Sometimes a one char token, sometimes two
			# If followed by '=', has a different meaning
			_check_no_lead_white_space()
			
			var next: String = _peek()
			if next == "=":
				_advance()
				_add_token(Token.PERCENT_EQUAL)
			else:
				_add_token(Token.PERCENT)
		"&":
			# Sometimes a one char token, sometimes two
			# If followed by self or '=', has a different meaning
			_check_no_lead_white_space()
			
			var next: String = _peek()
			if next == "=":
				_advance()
				_add_token(Token.BIT_AND_EQUAL)
			elif next == "&":
				_advance()
				_add_token(Token.AND)
			else:
				_add_token(Token.BIT_AND)
		"|":
			# Sometimes a one char token, sometimes two
			# If followed by self or '=', has a different meaning
			_check_no_lead_white_space()
			
			var next: String = _peek()
			if next == "=":
				_advance()
				_add_token(Token.BIT_OR_EQUAL)
			elif next == "|":
				_advance()
				_add_token(Token.OR)
			else:
				_add_token(Token.BIT_OR)
		"^":
			# Sometimes a one char token, sometimes two
			# If followed by self or '=', has a different meaning
			_check_no_lead_white_space()
			
			var next: String = _peek()
			if next == "=":
				_advance()
				_add_token(Token.BIT_XOR_EQUAL)
			elif next == "^":
				_advance()
				_add_token(Token.XOR)
			else:
				_add_token(Token.BIT_XOR)
		"!":
			# Sometimes a one char token, sometimes two
			# If followed by '=', has a different meaning
			_check_no_lead_white_space()
			
			var next: String = _peek()
			if next == "=":
				_advance()
				_add_token(Token.NOT_EQUAL)
			else:
				_add_token(Token.NOT)
		"=":
			# Sometimes a one char token, sometimes two
			# If followed by '=', has a different meaning
			_check_no_lead_white_space()
			
			var next: String = _peek()
			if next == "=":
				_advance()
				_add_token(Token.COMP_EQUAL)
			else:
				_add_token(Token.SET_EQUAL)
		"<":
			# Sometimes a one char token, sometimes two
			# If followed by self or '=', has a different meaning
			_check_no_lead_white_space()
			
			var next: String = _peek()
			if next == "=":
				_advance()
				_add_token(Token.LESS_EQUAL)
			elif next == "<":
				_advance()
				_add_token(Token.LEFT_SHIFT)
			else:
				_add_token(Token.LESS)
		">":
			# Sometimes a one char token, sometimes two
			# If followed by self or '=', has a different meaning
			_check_no_lead_white_space()
			
			var next: String = _peek()
			if next == "=":
				_advance()
				_add_token(Token.MORE_EQUAL)
			elif next == ">":
				_advance()
				_add_token(Token.RIGHT_SHIFT)
			else:
				_add_token(Token.MORE)
		"#":
			# Comment: Eats rest of line, no token created
			_check_no_lead_white_space()
			
			while _peek() != "\n" and not _is_at_end():
				_advance()
		" ":
			# If not at start or inside parens, does nothing other than separating other tokens
			# If at start and outside of parens, leading whitespace time
			if line_start and paren_layer == 0:
				var white_space: String = " "
				
				# Get all of the white space
				while _peek() in [" ", "\t"]:
					var character: String = _advance()
					white_space += character
					
					if character == "\t":
						interpreter.error_handler.warn(line, "Mixed tabs and spaces")
				
				var current_has_last: bool = white_space in last_line_white_space
				var last_has_current: bool = white_space in last_line_white_space
				
				if current_has_last and not last_has_current:
					# We must have added indentation
					_add_token(Token.INDENT)
				elif current_has_last and not last_has_current:
					# We must have removed indentation
					_add_token(Token.OUTDENT)
				elif current_has_last and last_has_current:
					# Indentation wasn't added nor was it removed
					pass
				else:
					# Indentation mismatch caused by different mix of tabs and spaces
					interpreter.error_handler.error(line, "Indentation mismatch")
				
				last_line_white_space = white_space
				line_start = false
		"\t":
			# If not at start or inside parens, does nothing other than separating other tokens
			# If at start and outside of parens, leading whitespace time
			if line_start and paren_layer == 0:
				var white_space: String = "\t"
				
				# Get all of the white space
				while _peek() in [" ", "\t"]:
					var character: String = _advance()
					white_space += character
					
					if character == " ":
						interpreter.error_handler.warn(line, "Mixed tabs and spaces")
				
				var current_has_last: bool = white_space in last_line_white_space
				var last_has_current: bool = white_space in last_line_white_space
				
				if current_has_last and not last_has_current:
					# We must have added indentation
					_add_token(Token.INDENT)
				elif current_has_last and not last_has_current:
					# We must have removed indentation
					_add_token(Token.OUTDENT)
				elif current_has_last and last_has_current:
					# Indentation wasn't added nor was it removed
					pass
				else:
					# Indentation mismatch caused by different mix of tabs and spaces
					interpreter.error_handler.error(line, "Indentation mismatch")
				
				last_line_white_space = white_space
				line_start = false
		"\r":
			# Just ignore it
			pass
		"\n":
			# Increase line num
			line += 1
			line_start = true
			# Add new line token if not in parens
			if paren_layer == 0:
				_add_token(Token.NEW_LINE)
		"'":
			# Chars: Take "'" + some character + "'"
			_check_no_lead_white_space()
			
			var character = _advance()
			
			if character == "\\":
				character = _advance()
				if character in ["'", "\"", "\\", "$"]:
					# Valid chars to escape, no need for us to modify
					pass
				elif character in ["n", "r", "t"]:
					# Must be turned into escaped form
					character = ("\\" + character).c_unescape()
				else:
					# Bad
					interpreter.error_handler.error(line, "Invalid escape character")
			
			if _peek() == "'":
				_advance()
				_add_token(Token.LITERAL, character, "char")
			else:
				interpreter.error_handler.error(line, "Unclosed or too long char")
		"\"":
			# Strings: Like chars but take several characters
			_check_no_lead_white_space()
			
			var start_line: int = line
			
			var string: String = ""
			
			while _peek() != "\"" and not _is_at_end():
				var next: String = _advance()
				
				if next == "\n":
					string += "\n"
					line += 1
				elif next == "\\":
					var escaped = _advance()
					if escaped in ["'", "\"", "\\", "$"]:
						# Valid chars to escape, no need for us to modify
						string += escaped
					elif escaped in ["n", "r", "t"]:
						# Must be turned into escaped form
						string += ("\\" + escaped).c_unescape()
					else:
						# Bad
						interpreter.error_handler.error(line, "Invalid escape character")
				else:
					string += next
			
			if _peek() != "\"":
				interpreter.error_handler.error(start_line, "Unclosed string")
			
			# Eat closing "
			_advance()
			
			_add_token(Token.LITERAL, string, "string")
		_:
			if _is_digit(c):
				_check_no_lead_white_space()
				var int_part: int = c.to_int()
				
				while _is_digit(_peek()):
					int_part = int_part * 10 + _advance().to_int()
				
				if _peek() == ".":
					var value: float = int_part
					_advance()
					
					var place_num: int = 0
					while _is_digit(_peek()):
						place_num += 1
						value += _advance().to_int() / pow(10, place_num)
					
					_add_token(Token.LITERAL, value, "float")
				else:
					_add_token(Token.LITERAL, int_part, "int")
			elif _is_alpha(c):
				_check_no_lead_white_space()
				
				var identifier: String = c
				
				while _is_alphanumeric(_peek()):
					c += _advance()
				
				if identifier == "true":
					_add_token(Token.LITERAL, true, "bool")
				elif identifier == "false":
					_add_token(Token.LITERAL, false, "bool")
				elif identifier == "null":
					_add_token(Token.LITERAL, null, "null")
				elif identifier in Token.KEYWORDS:
					_add_token(Token.KEYWORDS[identifier])
				else:
					_add_token(Token.IDENTIFIER)
			else:
				var errorText: String = "Unexpected character '%s'" % c
				interpreter.error_handler.error(line, errorText)


## Finds all tokens and returns them
func scan_tokens() -> Array[Token]:
	while not _is_at_end():
		start = current
		_scan_token()
	
	_add_token(Token.EOF)
	
	return tokens
