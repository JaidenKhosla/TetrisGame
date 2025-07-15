@tool
class_name Grid extends Node3D

@onready var CUBE_SIZE: Vector3 =  await (InitNode.get_node("GameCube") as GameCube).get_size()
@onready var TICK_SPEED_TIMER: Timer = $TICK_SPEED


var Tetrimino_Arrangements = TetriminoArrangements.new()
@onready var Shapes = Tetrimino_Arrangements.shapes
@onready var GridParts = $GridParts
var packed_grid_cube = preload("res://Scenes/GridBlock.tscn")
const ROWS = 20;
const COLUMNS = 10;


var GRID: Array[Array] = []

@onready var SELECTED_TETRIMINO: Tetrimino = $Tetrimino
var initialPrev = Vector3(-1,-1,-1)
var prevPos = initialPrev

@onready var TOP = self.global_position.y + CUBE_SIZE.y

func to_global_direction(pos: Vector3) -> Vector3:
	return pos*CUBE_SIZE*0.75
	
func to_grid_coords(pos: Vector3) -> Vector3i:
	return Vector3i(
		round((pos.x - global_position.x)/(CUBE_SIZE.x*0.75)),
		round(ROWS-(pos.y - global_position.y)/(CUBE_SIZE.y*0.75)),
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

func _ready() -> void:
	setupGrid()
	SELECTED_TETRIMINO.addShape(Tetrimino_Arrangements.j)
	SELECTED_TETRIMINO.draw(Vector3(0,0,0))
	
func handle_move(global_direction: Vector3) -> void:
	if not SELECTED_TETRIMINO: return
	
	print(SELECTED_TETRIMINO.cubes)
	
	for cube in SELECTED_TETRIMINO.cubes:
		var goalCubePos = to_grid_coords(cube.global_position + global_direction)
		print(goalCubePos)
		if goalCubePos.x < 0 or goalCubePos.x >= GRID[0].size() or goalCubePos.y < 0:
			return
	await SELECTED_TETRIMINO.tween_move(global_direction)
		
func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	if Input.is_action_just_pressed("RIGHT") and SELECTED_TETRIMINO:
		await handle_move(to_global_direction(Vector3(1,0,0)))
	elif Input.is_action_just_pressed("LEFT") and SELECTED_TETRIMINO:
		await handle_move(to_global_direction(Vector3(-1,0,0)))
	elif Input.is_action_just_pressed("ROTATE") and SELECTED_TETRIMINO:
		await SELECTED_TETRIMINO.rotate_piece()
	#print("WORLD COORDS: %v, GRID COORDS: %v" % [SELECTED_TETRIMINO.curr_origin, to_grid_coords(SELECTED_TETRIMINO.curr_origin)])
