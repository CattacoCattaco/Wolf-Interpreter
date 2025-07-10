class_name Game
extends Control

@export var timer: Timer
@export var cell_grid: CellGrid

# Amount of seconds between _fixed_update ticks
var _fixed_update_speed: float = 0.13


func _ready() -> void:
	timer.wait_time = _fixed_update_speed
	timer.start()
	timer.timeout.connect(_fixed_update)
	_start()


func _start() -> void:
	pass


func _process(delta: float) -> void:
	_update(delta)


func _update(delta: float) -> void:
	pass


func _fixed_update() -> void:
	pass
