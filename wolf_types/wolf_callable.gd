class_name WolfCallable
extends RefCounted
## Represents a Wolf language callable


## Checks if the given args are of the correct amount and types for the function
func _args_fit(arg_types: Array[String]) -> bool:
	return false


## Checks the return type of the function based on the amount and types of the args
func _ret_type(arg_types: Array[String]) -> String:
	return ""


## Calls the function
## Void funcs return null
func _call(args: Array[Variant]) -> Variant:
	return null
