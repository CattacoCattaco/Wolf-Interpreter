class_name Lexer
extends RefCounted


var source: String
var tokens: Array[Token]

var start: int = 0
var current: int = 0
var line: int = 1

var line_start: bool = true
var last_line_white_space: String = ""

var paren_layer: int = 0
