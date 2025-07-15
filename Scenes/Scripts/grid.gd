@tool
class_name Grid extends Node3D

@onready var CUBE_SIZE: Vector3 =  await (InitNode.get_node("GameCube") as GameCube).get_size()
@onready var TICK_SPEED_TIMER: Timer = $TICK_SPEED

const ROWS = 20;
const COLUMNS = 10;

var GRID: Array[Array] = []

@onready var SELECTED_TETRIMINO: Tetrimino = $TetrisBlockJ

@onready var TOP = self.global_position.y + CUBE_SIZE.y

func setupGrid():
	GRID.resize(ROWS);
	for i in range(GRID.size()):
		GRID[i] = []
		GRID[i].resize(COLUMNS)
		
func is_pos_in_bounds(pos: Vector3) -> bool:
	print("POS: %f" % pos.x)
	print("LEFT_BORDER: %f" % global_position.x)
	print("RIGHT_BORDER: %f" % (global_position.x + (CUBE_SIZE.x * COLUMNS)))
	
	if pos.x < global_position.x or pos.x >= global_position.x + (CUBE_SIZE.x * COLUMNS):
		return false
	#if pos.y < global_position.y or pos.y > global_position.y + (CUBE_SIZE.y * ROWS):
		#return false

	return true
	
func to_grid_coords(pos: Vector3) -> Vector3i:
	return Vector3i(
		int(floor((pos.x - global_position.x)/CUBE_SIZE.x)),
		int(floor((pos.y - global_position.y)/CUBE_SIZE.y)),
		int(floor((pos.z - global_position.z)/CUBE_SIZE.z))
	)

func to_global_coords(grid_coords: Vector3i) -> Vector3:
	return Vector3(grid_coords.x, grid_coords.y, grid_coords.z)*CUBE_SIZE+global_position

func is_occupied(grid_pos: Vector3i) -> bool:
	if grid_pos.x < 0 or grid_pos.x >= COLUMNS:
		return false
	if grid_pos.y < 0 or grid_pos.y >= ROWS:
		return false
	return GRID[grid_pos.y][grid_pos.x] != null

func move(tetrimino: Tetrimino, direction: Vector3i):
	print("Called!")
	if not tetrimino: return
	print("Moving")
	for cube in tetrimino.cubes:
		var destination = to_grid_coords(cube.global_position)+direction
		
		print("POS %s" % str(cube.global_position))
		print("Global POS (FUNC): %s" % str(to_global_coords(destination)))
		print("In Bounds: %s" % str(is_pos_in_bounds(to_global_coords(destination))))
		print("Occupied: %s" % str(is_occupied(destination)))
		
		print("\n")
		
		if(not is_pos_in_bounds(to_global_coords(destination))):
			print("AHH")
			return false
	for cube in tetrimino.cubes:
		var from = to_grid_coords(cube.global_position)
		var destination = from+direction
		GRID[destination.y][destination.x] = cube
		GRID[from.y][from.x] = null
		
	await tetrimino.tween_move(Vector3(direction.x, direction.y, direction.z)*CUBE_SIZE)

var curr = 0

func _ready() -> void:
	setupGrid();
	curr = Time.get_unix_time_from_system()

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	if Input.is_action_just_pressed("LEFT"):
		await move(SELECTED_TETRIMINO, Vector3i(-1,0,0))
	if Input.is_action_just_pressed("RIGHT"):
		await move(SELECTED_TETRIMINO, Vector3i(1,0,0))
