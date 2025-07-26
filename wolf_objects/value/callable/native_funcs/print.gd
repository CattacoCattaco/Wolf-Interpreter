class_name Print
extends WolfCallable
## Reprsents the clear console function

## A reference to the interpreter
var interpreter: Interpreter


func _init(p_interpreter: Interpreter) -> void:
	definitions = [
		CallableDefenition.new([
			CallableArg.new("text", Typer.data_types["value"], false, null, true)
		], Typer.data_types["void"])
	]
	
	interpreter = p_interpreter


## Calls the function
## Void funcs return null
func _call(args: Array[WolfObject], definition: CallableDefenition, line_num: int) -> WolfObject:
	for arg: Variant in args:
		interpreter.console.println(str(arg))
	return WolfVoid.new()
