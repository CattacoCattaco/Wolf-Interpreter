class_name WolfNullable
extends WolfValue
## Represents a Wolf language object

var is_null: bool = false


func _get_type() -> WolfType:
	return Typer.data_types["nullable"]


func _to_string() -> String:
	if is_null:
		return "null"
	
	return str(value)
