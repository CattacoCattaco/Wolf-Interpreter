class_name WolfString
extends WolfValue
## Represents a Wolf language object


func _init(text: String) -> void:
	value = text


func _get_type() -> WolfType:
	return Typer.data_types["string"]


func _to_string() -> String:
	return str(value)
