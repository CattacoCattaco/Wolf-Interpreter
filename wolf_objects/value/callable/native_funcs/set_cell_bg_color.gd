class_name SetCellBGColor
extends WolfCallable
## Reprsents the clear console function

## A reference to the interpreter
var interpreter: Interpreter


func _init(p_interpreter: Interpreter) -> void:
	definitions = [
		CallableDefenition.new([
			CallableArg.new("cell_x", Typer.data_types["int"], false, null, false),
			CallableArg.new("cell_y", Typer.data_types["int"], false, null, false),
			CallableArg.new("hex_code", Typer.data_types["string"], false, null, false),
		], Typer.data_types["string"]),
		CallableDefenition.new([
			CallableArg.new("cell_x", Typer.data_types["int"], false, null, false),
			CallableArg.new("cell_y", Typer.data_types["int"], false, null, false),
			CallableArg.new("color_r", Typer.data_types["char"], false, null, false),
			CallableArg.new("color_g", Typer.data_types["char"], false, null, false),
			CallableArg.new("color_b", Typer.data_types["char"], false, null, false),
		], Typer.data_types["string"]),
	]
	
	interpreter = p_interpreter


## Calls the function
## Void funcs return null
func _call(args: Array[WolfObject], definition: CallableDefenition, line_num: int) -> WolfObject:
	if len(args) == 3:
		if not args[2].value.is_valid_html_color():
			interpreter.error_handler.error(line_num, "Invalid color code: %s" % args[2])
			return WolfVoid.new()
		
		var cell: Cell = interpreter.game.cell_grid.get_cell(args[0].value, args[1].value)
		cell.set_bg_color(Color(args[2].value))
	elif len(args) == 5:
		var cell: Cell = interpreter.game.cell_grid.get_cell(args[0].value, args[1].value)
		var r: float = (args[2].value & 255) / 255.0
		var g: float = (args[3].value & 255) / 255.0
		var b: float = (args[4].value & 255) / 255.0
		cell.set_bg_color(Color(r, g, b))
	
	return WolfVoid.new()
