class_name WolfFloat
extends WolfNum
## Represents a Wolf language object


func _init(num: float) -> void:
	value = num


func _get_type() -> WolfType:
	return Typer.data_types["float"]
