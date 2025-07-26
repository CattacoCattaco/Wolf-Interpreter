class_name WolfCallable
extends WolfValue
## Represents a Wolf language callable

var definitions: Array[CallableDefenition]


func _get_type() -> WolfType:
	return Typer.data_types["callable"]


func _arg_type_fits(arg_type: WolfType, expected_type: WolfType) -> bool:
	var num_type: WolfType = Typer.data_types["num"]
	var both_nums: bool = arg_type.inherits(num_type) and expected_type.inherits(num_type)
	
	return arg_type.inherits(expected_type) or both_nums


## Finds a matching definition of this function based on the argument types
## If there isn't one, returns null
func _def_to_use(arg_types: Array[WolfType]) -> CallableDefenition:
	for definition in definitions:
		if len(definition.args) == 0 and len(arg_types) == 0:
			return definition
		
		for i in len(definition.args):
			var expected_arg: CallableArg = definition.args[i]
			
			if len(arg_types) <= i:
				if expected_arg.has_default:
					# Only missing some optional args
					return definition
				else:
					# Not enough args for this definition
					break
			
			if _arg_type_fits(arg_types[i], expected_arg.arg_type):
				if i == len(definition.args) - 1:
					if i < len(arg_types) - 1:
						var end_args_all_fit: bool = true
						for j in range(i + 1, len(arg_types)):
							if not _arg_type_fits(arg_types[j], expected_arg.arg_type):
								end_args_all_fit = false
								break
						
						if not end_args_all_fit:
							break
					
					# All args match
					return definition
				
				# keep going
			else:
				# This definition doesn't use the right types
				break
	
	return null


## Calls the function
func _call(args: Array[WolfObject], definition: CallableDefenition, line_num: int) -> WolfObject:
	return null
