class_name Wait
extends WolfCallable
## Reprsents the clear console function

## A reference to the interpreter
var interpreter: Interpreter


func _init(p_interpreter: Interpreter) -> void:
	definitions = [
		CallableDefenition.new([
			CallableArg.new("text", Typer.data_types["int"], false, null, true),
		], Typer.data_types["void"]),
	]
	
	interpreter = p_interpreter


## Calls the function
## Void funcs return null
func _call(args: Array[WolfObject], definition: CallableDefenition, line_num: int) -> WolfObject:
	interpreter.game.timer.wait_time = (args[0].value as int) / 1000.0
	interpreter.game.timer.start()
	await interpreter.game.timer.timeout
	return null
