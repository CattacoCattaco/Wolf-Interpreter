class_name Prompt
extends WolfCallable
## Reprsents the clear console function

## A reference to the interpreter
var interpreter: Interpreter


func _init(p_interpreter: Interpreter) -> void:
	definitions = [
		CallableDefenition.new([
			CallableArg.new("prompt_text", Typer.data_types["string"], false, null, false)
		], Typer.data_types["string"])
	]
	
	interpreter = p_interpreter


## Calls the function
## Void funcs return null
func _call(args: Array[WolfObject], definition: CallableDefenition, line_num: int) -> WolfObject:
	interpreter.console.println(args[0].value)
	var result: String = await interpreter.console.input_submitted
	return WolfString.new(result)
