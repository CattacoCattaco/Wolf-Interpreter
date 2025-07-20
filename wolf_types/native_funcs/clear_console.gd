class_name ClearConsole
extends WolfCallable
## Reprsents the clear console function

## A reference to the interpreter
var interpreter: Interpreter


## Checks if the given args are of the correct amount and types for the function
func _args_fit(arg_types: Array[String]) -> bool:
	return len(arg_types) == 0


## Checks the return type of the function based on the amount and types of the args
func _ret_type(arg_types: Array[String]) -> String:
	if not _args_fit(arg_types):
		return "invalid args"
	
	return "void"


## Calls the function
## Void funcs return null
func _call() -> Variant:
	interpreter.console.clear_text()
	return null
