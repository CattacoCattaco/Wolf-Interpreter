class_name WolfBool
extends WolfValue
## Represents a Wolf language object


func _init(is_true: bool) -> void:
	value = is_true


func _get_type() -> WolfType:
	return Typer.data_types["bool"]


func _to_string() -> String:
	return str(value)
