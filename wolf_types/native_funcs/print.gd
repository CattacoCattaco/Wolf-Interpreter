class_name Print
extends WolfCallable
## Reprsents the clear console function

## A reference to the interpreter
var interpreter: Interpreter


func _init(p_interpreter: Interpreter) -> void:
	interpreter = p_interpreter


## Checks if the given args are of the correct amount and types for the function
func _args_fit(arg_types: Array[String]) -> bool:
	for arg_type in arg_types:
		if arg_type == "void":
			return false
	
	return len(arg_types) > 0


## Checks the return type of the function based on the amount and types of the args
func _ret_type(arg_types: Array[String]) -> String:
	if not _args_fit(arg_types):
		return "invalid args"
	
	return "void"


## Calls the function
## Void funcs return null
func _call(args: Array[Variant]) -> Variant:
	for arg: Variant in args:
		interpreter.console.println(str(arg))
		print(str(arg) + "?")
	return null
