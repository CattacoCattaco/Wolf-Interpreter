class_name Cell
extends ColorRect

@export var pixels: Array[ColorRect]

var cell_grid: CellGrid

var bg_color: Color
var char_color: Color
var char_num: int
var char_data: BitMap

var pos: Vector2i


func _ready() -> void:
	set_bg_color(Color(1, 1, 1))
	load_char_num(66)


func set_bg_color(new_color: Color) -> void:
	bg_color = new_color
	color = bg_color


func set_char_color(new_color: Color) -> void:
	char_color = new_color
	load_char_num(char_num)


func load_char_num(new_char_num: int) -> void:
	char_num = new_char_num
	
	var new_char_data: BitMap = cell_grid.char_datas[char_num]
	
	if new_char_data.get_size() != Vector2i(6, 6):
		return
	
	char_data = new_char_data
	
	for x in range(6):
		for y in range(6):
			set_pixel(x, y, char_color if char_data.get_bit(x, y) else Color(0, 0, 0, 0))


func set_pixel(x: int, y: int, pixel_color: Color) -> void:
	pixels[x + 6 * y].color = pixel_color


func get_pixel(x: int, y: int) -> Color:
	return pixels[x + 6 * y].color
