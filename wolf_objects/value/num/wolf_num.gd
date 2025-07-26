class_name WolfNum
extends WolfValue
## Represents a Wolf language object


func _get_type() -> WolfType:
	return Typer.data_types["num"]


func _to_string() -> String:
	return str(value)
