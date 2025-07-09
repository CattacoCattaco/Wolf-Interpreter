class_name SnakeGame
extends Control

@export var timer: Timer
@export var cell_grid: CellGrid

var move_dir := Vector2i(0, 0)

var apple_pos: Vector2i
var snake: Array[Vector2i]

var lost: bool = false

func _ready() -> void:
	timer.timeout.connect(update)
	_start()


func _start() -> void:
	lost = false
	randomize_apple_pos()
	snake = [Vector2i(7, 7)]
	move_dir = Vector2i(0, 0)
	display()


func _process(delta: float) -> void:
	var coming_from_below: bool = len(snake) > 2 and Vector2i(0, 1) + snake[0] in snake
	var coming_from_above: bool = len(snake) > 2 and Vector2i(0, -1) + snake[0] in snake
	var coming_from_left: bool = len(snake) > 2 and Vector2i(-1, 0) + snake[0] in snake
	var coming_from_right: bool = len(snake) > 2 and Vector2i(1, 0) + snake[0] in snake
	
	if Input.is_action_just_pressed("Down") and not coming_from_below:
		if timer.is_stopped():
			update()
			timer.start()
		
		move_dir = Vector2i(0, 1)
	elif Input.is_action_just_pressed("Up") and not coming_from_above:
		if timer.is_stopped():
			update()
			timer.start()
		
		move_dir = Vector2i(0, -1)
	elif Input.is_action_just_pressed("Left") and not coming_from_left:
		if timer.is_stopped():
			update()
			timer.start()
		
		move_dir = Vector2i(-1, 0)
	elif Input.is_action_just_pressed("Right") and not coming_from_right:
		if timer.is_stopped():
			update()
			timer.start()
		
		move_dir = Vector2i(1, 0)
	elif lost and Input.is_action_just_pressed("Reset"):
		_start()


func update() -> void:
	if not lost:
		move_snake()
		display()
	else:
		timer.stop()


func randomize_apple_pos() -> void:
	apple_pos = Vector2i(randi_range(0, 15), randi_range(0, 15))
	while apple_pos in snake:
		apple_pos = Vector2i(randi_range(0, 15), randi_range(0, 15))


func move_snake() -> void:
	if move_dir == Vector2i(0, 0):
		return
	
	var new_head_pos: Vector2i = move_dir + snake[0]
	
	if(new_head_pos != apple_pos):
		snake.remove_at(len(snake) - 1)
	else:
		randomize_apple_pos()
	
	if(new_head_pos in snake or not pos_in_bounds(new_head_pos)):
		lose()
	
	snake.push_front(new_head_pos)
	
	if apple_pos in snake:
		randomize_apple_pos()


func display() -> void:
	if lost:
		return
	
	for x: int in 16:
		for y: int in 16:
			cell_grid.get_cell(x, y).set_bg_color(Color(0, 0, 0))
			cell_grid.get_cell(x, y).load_char_num(66)
	
	cell_grid.get_cell_by_vec(apple_pos).set_char_color(Color(1, 0, 0))
	cell_grid.get_cell_by_vec(apple_pos).load_char_num(83)
	
	var light: bool = true
	
	for pos: Vector2i in snake:
		cell_grid.get_cell_by_vec(pos).load_char_num(66)
		cell_grid.get_cell_by_vec(pos).set_bg_color(Color(0, 1, 0) if light else Color(0, 0.8, 0))
		light = not light
	
	cell_grid.get_cell_by_vec(snake[0]).set_char_color(Color(0, 0.3, 0))
	match move_dir:
		Vector2i(-1, 0):
			cell_grid.get_cell_by_vec(snake[0]).load_char_num(115)
		Vector2i(0, -1):
			cell_grid.get_cell_by_vec(snake[0]).load_char_num(112)
		Vector2i(1, 0):
			cell_grid.get_cell_by_vec(snake[0]).load_char_num(113)
		Vector2i(0, 1):
			cell_grid.get_cell_by_vec(snake[0]).load_char_num(114)
		Vector2i(0, 0):
			cell_grid.get_cell_by_vec(snake[0]).load_char_num(112)


func lose() -> void:
	lost = true
	
	for x: int in 16:
		for y: int in 16:
			cell_grid.get_cell(x, y).load_char_num(66)
			cell_grid.get_cell(x, y).set_bg_color(Color(0.1, 0, 0))
			print(cell_grid.get_cell(x, y).bg_color)
			print(cell_grid.get_cell(x, y).color)


func pos_in_bounds(pos: Vector2i) -> bool:
	return pos.x <= 15 and pos.x >= 0 and pos.y <= 15 and pos.y >= 0
