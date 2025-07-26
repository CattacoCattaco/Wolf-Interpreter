class_name WolfInt
extends WolfNum
## Represents a Wolf language object


func _init(num: int) -> void:
	value = num


func _get_type() -> WolfType:
	return Typer.data_types["int"]
