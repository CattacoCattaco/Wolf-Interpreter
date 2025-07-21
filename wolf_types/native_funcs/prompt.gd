class_name Prompt
extends WolfCallable
## Reprsents the clear console function

## A reference to the interpreter
var interpreter: Interpreter


func _init(p_interpreter: Interpreter) -> void:
	interpreter = p_interpreter


## Checks if the given args are of the correct amount and types for the function
func _args_fit(arg_types: Array[String]) -> bool:
	return len(arg_types) == 1 and arg_types[0] == "string"


## Checks the return type of the function based on the amount and types of the args
func _ret_type(arg_types: Array[String]) -> String:
	if not _args_fit(arg_types):
		return "invalid args"
	
	return "string"


## Calls the function
## Void funcs return null
func _call(args: Array[Variant]) -> Variant:
	interpreter.console.println(args[0])
	var result: String = await interpreter.console.input_submitted
	print("User said: " + result)
	return result
