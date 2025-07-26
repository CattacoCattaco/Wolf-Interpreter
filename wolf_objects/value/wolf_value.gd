class_name WolfValue
extends WolfObject
## Represents a Wolf language object

var value: Variant


func _get_type() -> WolfType:
	return Typer.data_types["value"]


func _get_value() -> Variant:
	return value


func _to_string() -> String:
	return "<value>"
