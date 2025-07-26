class_name CallableDefenition
extends RefCounted

var args: Array[CallableArg]
var return_type: WolfType
var block: Statement.Block


func _init(p_args: Array[CallableArg], p_return_type: WolfType, 
		p_block: Statement.Block = null) -> void:
	args = p_args
	return_type = p_return_type
	block = p_block
