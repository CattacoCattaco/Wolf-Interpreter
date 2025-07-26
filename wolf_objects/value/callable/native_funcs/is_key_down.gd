class_name IsKeyDown
extends WolfCallable
## Reprsents the clear console function

## A reference to the interpreter
var interpreter: Interpreter


func _init(p_interpreter: Interpreter) -> void:
	definitions = [
		CallableDefenition.new([
			CallableArg.new("key_code", Typer.data_types["int"], false, null, false)
		], Typer.data_types["bool"])
	]
	
	interpreter = p_interpreter


## Calls the function
## Void funcs return null
func _call(args: Array[WolfObject], definition: CallableDefenition, line_num: int) -> WolfObject:
	return WolfBool.new(Input.is_key_pressed(args[0].value))
