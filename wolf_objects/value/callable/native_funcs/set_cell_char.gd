class_name SetCellChar
extends WolfCallable
## Reprsents the clear console function

## A reference to the interpreter
var interpreter: Interpreter


func _init(p_interpreter: Interpreter) -> void:
	definitions = [
		CallableDefenition.new([
			CallableArg.new("cell_x", Typer.data_types["int"], false, null, false),
			CallableArg.new("cell_y", Typer.data_types["int"], false, null, false),
			CallableArg.new("char_code", Typer.data_types["char"], false, null, false),
		], Typer.data_types["string"]),
	]
	
	interpreter = p_interpreter


## Calls the function
## Void funcs return null
func _call(args: Array[WolfObject], definition: CallableDefenition, line_num: int) -> WolfObject:
	var cell: Cell = interpreter.game.cell_grid.get_cell(args[0].value, args[1].value)
	if (args[2].value & 255) > 127:
		interpreter.error_handler.error(line_num, "Invalid character code: %s" % args[2])
		return null
	
	cell.load_char_num(args[2].value & 255)
	
	return null
