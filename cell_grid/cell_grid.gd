class_name CellGrid
extends GridContainer

@export var cell_scene: PackedScene

@export var chars: AtlasTexture

@export var grid_size: int = 16

var cells: Array[Cell] = []

var char_datas: Array[BitMap] = []


func _ready() -> void:
	for y in 8:
		for x in 16:
			chars.region.position.x = 6 * x
			chars.region.position.y = 6 * y
			
			var bit_map: BitMap = BitMap.new()
			bit_map.create_from_image_alpha(chars.get_image())
			
			char_datas.append(bit_map)
	
	columns = grid_size
	
	for y in range(grid_size):
		for x in range(grid_size):
			var cell: Cell = cell_scene.instantiate()
			
			cell.pos = Vector2i(x, y)
			cell.cell_grid = self
			
			add_child(cell)
			cells.append(cell)
			
			cell.set_bg_color(Color(0, 0, 0))


func get_cell(x: int, y: int) -> Cell:
	return cells[x + y * grid_size]


func get_cell_by_vec(vec: Vector2i) -> Cell:
	return cells[vec.x + vec.y * grid_size]
