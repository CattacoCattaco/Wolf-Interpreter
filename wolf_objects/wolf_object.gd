class_name WolfObject
extends RefCounted
## Represents a Wolf language object


func _get_type() -> WolfType:
	return Typer.data_types["any"]
