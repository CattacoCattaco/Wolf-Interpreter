class_name CallableArg
extends RefCounted

var arg_name: String
var arg_type: WolfType
var has_default: bool
var default_value: WolfValue
var accept_any_amount: bool


func _init(p_arg_name: String, p_arg_type: WolfType, p_has_default: bool, 
		p_default_value: WolfValue, p_accept_any_amount: bool) -> void:
	arg_name = p_arg_name
	arg_type = p_arg_type
	has_default = p_has_default
	default_value = p_default_value
	accept_any_amount = p_accept_any_amount
