class_name WolfChar
extends WolfNum
## Represents a Wolf language object


func _init(num: int) -> void:
	value = num & 255


func _get_type() -> WolfType:
	return Typer.data_types["char"]
