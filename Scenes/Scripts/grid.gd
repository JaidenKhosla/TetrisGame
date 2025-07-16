@tool
class_name Grid extends Node3D

@onready var CUBE_SIZE: Vector3 =  await (InitNode.get_node("GameCube") as GameCube).get_size()
@export var TICK_SPEED: float = 1.5 #seconds between each tick


var Tetrimino_Arrangements = TetriminoArrangements.new()
@onready var Shapes = Tetrimino_Arrangements.shapes
@onready var GridParts = $GridParts
var tetrimino = preload("res://Scenes/tetrimino.tscn")
var packed_grid_cube = preload("res://Scenes/GridBlock.tscn")
const ROWS = 20;
const COLUMNS = 10;


var GRID: Array[Array] = []

@onready var SELECTED_TETRIMINO: Tetrimino
var initialPrev = Vector3(-1,-1,-1)
var prevPos = initialPrev

@onready var TOP: float = self.global_position.y + (ROWS-2)*CUBE_SIZE.y*0.75
@onready var SPAWNING_POSITION: Vector3 = to_global_coords(Vector3i(3,0,0)) + Vector3(0,TOP,0)


func to_global_coords(pos: Vector3i) -> Vector3:
	return global_position+to_global_direction(pos);

func to_global_direction(pos: Vector3) -> Vector3:
	var global_coords = pos*CUBE_SIZE*0.75
	return global_coords
	
func to_grid_coords(pos: Vector3) -> Vector3i:
	return Vector3i(
		round((pos.x - global_position.x)/(CUBE_SIZE.x*0.75)),
		round(ROWS-1-(pos.y - global_position.y)/(CUBE_SIZE.y*0.75)),
		round((pos.z - global_position.x)/(CUBE_SIZE.z*0.75))
	)


func setupGrid():
	GRID.resize(ROWS);
	for i in range(GRID.size()):
		GRID[i] = []
		GRID[i].resize(COLUMNS)
	for row in range(-1,ROWS+1):
		for col in range(-1,COLUMNS+1):
			var pushForward: bool = -1 in [row, col] or row == ROWS or col == COLUMNS
			var pos = Vector3(col*(CUBE_SIZE.x*0.75), (row*CUBE_SIZE.y*0.75), -154.5 if not pushForward else 0)
			var grid_cube: GameCube = packed_grid_cube.instantiate()
			GridParts.add_child(grid_cube)
			if pushForward: grid_cube.color = GameCube.COLORS.LIGHT_GREY
			grid_cube.position = pos

func spawn_random_piece():
	var randomColor = GameCube.usableColors.pick_random()
	
	var shape = Shapes.pick_random()
	
	var newTetrimino: Tetrimino = tetrimino.instantiate()
	newTetrimino.COLOR = randomColor as GameCube.COLORS
	add_child(newTetrimino)
	
	newTetrimino.addShape(shape)
	SELECTED_TETRIMINO = newTetrimino
	SELECTED_TETRIMINO.draw(SPAWNING_POSITION)
func set_piece() -> void:
	if not SELECTED_TETRIMINO: return
	for cube in SELECTED_TETRIMINO.cubes:
		if cube is GameCube:
			var gridCoords = to_grid_coords(cube.global_position)
			GRID[gridCoords.y][gridCoords.x] = cube
	await SELECTED_TETRIMINO.blink()
	SELECTED_TETRIMINO = null

func _ready() -> void:
	print(SPAWNING_POSITION)
	setupGrid()
	#SELECTED_TETRIMINO.addShape(Tetrimino_Arrangements.j)
	#SELECTED_TETRIMINO.draw(Vector3(0,0,0))
	
	spawn_random_piece()
func not_in_bounds(goalCubePos: Vector3i) -> bool:
	return goalCubePos.x < 0 or goalCubePos.x >= GRID[0].size() or goalCubePos.y < 0 or goalCubePos.y >= GRID.size()
func is_occupied(goalCubePos: Vector3i) -> bool:
	return not_in_bounds(goalCubePos) or GRID[goalCubePos.y][goalCubePos.x] != null

func handle_rotate() -> void:
	if not SELECTED_TETRIMINO: return
	
	var nextShape = SELECTED_TETRIMINO.shape[(SELECTED_TETRIMINO.curr_idx+1)%SELECTED_TETRIMINO.shape.size()]
	var origin = SELECTED_TETRIMINO.curr_origin
	
	for part in nextShape:
		var pos = to_grid_coords(origin+ Vector3(part.x, part.y, 0)*CUBE_SIZE*0.75)
		if not_in_bounds(pos) or is_occupied(pos): return
	
	await SELECTED_TETRIMINO.rotate_piece()
	

func handle_move(global_direction: Vector3) -> void:
	if not SELECTED_TETRIMINO: return
		
	for cube in SELECTED_TETRIMINO.cubes:
		var goalCubePos = to_grid_coords(cube.global_position + global_direction)
		if not_in_bounds(goalCubePos) or is_occupied(goalCubePos):
			return
	await SELECTED_TETRIMINO.tween_move(global_direction)

var prevTime = 0
func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	if Input.is_action_just_pressed("RIGHT") and SELECTED_TETRIMINO:
		await handle_move(to_global_direction(Vector3(1,0,0)))
	elif Input.is_action_just_pressed("LEFT") and SELECTED_TETRIMINO:
		await handle_move(to_global_direction(Vector3(-1,0,0)))
	elif Input.is_action_just_pressed("ui_down") and SELECTED_TETRIMINO:
		await handle_move(to_global_direction(Vector3(0,-1,0)))
	elif Input.is_action_just_pressed("ROTATE") and SELECTED_TETRIMINO:
		await handle_rotate()
	#print("WORLD COORDS: %v, GRID COORDS: %v" % [SELECTED_TETRIMINO.curr_origin, to_grid_coords(SELECTED_TETRIMINO.curr_origin)])
