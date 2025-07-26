class_name WolfType
extends RefCounted
## Represents a Wolf language data type

var base_type_name: String
var parent_type: WolfType
var children_types: Array[WolfType]

var type_placeholder_count: int
var type_placeholders_used: Array[WolfType]


func _init(p_base_type_name: String, p_parent_type: WolfType, 
		p_type_placeholder_count: int, p_type_placeholders_used: Array[WolfType]) -> void:
	base_type_name = p_base_type_name
	parent_type = p_parent_type
	type_placeholder_count = p_type_placeholder_count
	type_placeholders_used = p_type_placeholders_used


func _to_string() -> String:
	if len(type_placeholders_used) == 0:
		return base_type_name
	
	var ret_text: String = "%s[%s" % base_type_name
	
	for i in range(1, len(type_placeholders_used)):
		ret_text += ", " + str(type_placeholders_used[i])
	
	ret_text += "]"
	
	return ret_text


## Adds child_type to children_types
func add_child_type(child_type: WolfType) -> void:
	children_types.append(child_type)


## Checks if this type inherits check_type
## Including if check_type IS this type
func inherits(check_type: WolfType) -> bool:
	if check_type == self:
		return true
	
	if check_type == parent_type:
		return true
	
	# We are at any and still no match
	if not parent_type:
		return false
	
	return parent_type.inherits(check_type)


## Finds the type which is the most complex which this type and other_type both inherit
func get_least_common_ancestor(other_type: WolfType) -> WolfType:
	# If other_type inherits this type, return self
	if other_type.inherits(self):
		return self
	
	# If this type inherits other type, return other_type
	if inherits(other_type):
		return other_type
	
	# Go as far back as necessary in this type's lineage
	# to find a type which is inheritted by other_type
	# Worst case: Will return any
	var ancestor: WolfType = parent_type
	
	while not ancestor.is_inheritted_by(other_type):
		ancestor = ancestor.parent_type
	
	return ancestor
