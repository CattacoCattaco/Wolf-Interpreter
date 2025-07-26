class_name WolfEnvironment
extends RefCounted

var values: Dictionary[String, WolfObject] = {}
var types: Dictionary[String, WolfType] = {}

var parent_environment: WolfEnvironment


func _init(p_parent_environment: WolfEnvironment = null) -> void:
	parent_environment = p_parent_environment


func get_value(var_name: String) -> WolfObject:
	if var_name in values:
		return values[var_name]
	elif parent_environment:
		return parent_environment.get_value(var_name)
	
	return null


func set_value(var_name: String, value: WolfObject) -> void:
	if var_name in values:
		values[var_name] = value
		return
	elif parent_environment:
		parent_environment.set_value(var_name, value)


func get_type(var_name: String) -> WolfType:
	if var_name in types:
		return types[var_name]
	elif parent_environment:
		return parent_environment.get_type(var_name)
	
	return null


func var_has_type(var_name: String) -> bool:
	if var_name in types:
		return true
	elif parent_environment:
		return parent_environment.var_has_type(var_name)
	
	return false


func var_has_value(var_name: String) -> bool:
	if var_name in values:
		return true
	elif parent_environment:
		return parent_environment.var_has_value(var_name)
	
	return false
