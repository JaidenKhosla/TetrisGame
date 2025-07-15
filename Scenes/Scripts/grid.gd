@tool
class_name Grid extends Node3D

@onready var CUBE_SIZE: Vector3 =  await (InitNode.get_node("GameCube") as GameCube).get_size()
@onready var TICK_SPEED_TIMER: Timer = $TICK_SPEED

const ROWS = 20;
const COLUMNS = 10;

var GRID: Array[Array] = []

@onready var SELECTED_TETRIMINO: Tetrimino = $TetrisBlockJ
var initialPrev = Vector3(-1,-1,-1)
var prevPos = initialPrev

@onready var TOP = self.global_position.y + CUBE_SIZE.y

func setupGrid():
	GRID.resize(ROWS);
	for i in range(GRID.size()):
		GRID[i] = []
		GRID[i].resize(COLUMNS)

func setPiece() -> void:
	await SELECTED_TETRIMINO.blink()
	SELECTED_TETRIMINO = null
	
func is_pos_in_bounds(pos: Vector3) -> bool:
	#print("POS: %f" % pos.x)
	#print("LEFT_BORDER: %f" % global_position.x)
	#print("RIGHT_BORDER: %f" % (global_position.x + (CUBE_SIZE.x * COLUMNS)))
	
	if pos.x < global_position.x or pos.x >= global_position.x + (CUBE_SIZE.x * COLUMNS):
		return false
	if pos.y < global_position.y or pos.y >= global_position.y + (CUBE_SIZE.y * ROWS):
		print("Hit vertical bounds")
		setPiece()
		return false	

	return true
	
func to_grid_coords(pos: Vector3) -> Vector3i:
	return Vector3i(
		int(floor((pos.x - global_position.x)/CUBE_SIZE.x)),
		int(floor((pos.y - global_position.y)/CUBE_SIZE.y)),
		int(floor((pos.z - global_position.z)/CUBE_SIZE.z))
	)

func to_global_coords(grid_coords: Vector3i) -> Vector3:
	return Vector3(grid_coords.x, grid_coords.y, grid_coords.z)*CUBE_SIZE+global_position

func is_occupied(grid_pos: Vector3i, cube: GameCube) -> bool:
	if grid_pos.x < 0 or grid_pos.x >= COLUMNS:
		return false
	if grid_pos.y < 0 or grid_pos.y >= ROWS:
		return false
	return GRID[grid_pos.y][grid_pos.x] != null and GRID[grid_pos.y][grid_pos.x] != cube

func move(tetrimino: Tetrimino, direction: Vector3i):
	print("Called!")
	if not tetrimino: return
	print("Moving")
	for cube in tetrimino.cubes:
		var destination = to_grid_coords(cube.global_position)+direction
		
		#print("POS %s" % str(cube.global_position))
		#print("Global POS (FUNC): %s" % str(to_global_coords(destination)))
	##	print("In Bounds: %s" % str(is_pos_in_bounds(to_global_coords(destination))))
		#print("Occupied: %s" % str(is_occupied(destination)))
		#
		#print("\n")
		
		if(not await is_pos_in_bounds(to_global_coords(destination)) or is_occupied(to_global_coords(destination), cube)):
			print("AHH")
			return false
	for cube in tetrimino.cubes:
		var from = to_grid_coords(cube.global_position)
		var destination = from+direction
		GRID[destination.y][destination.x] = cube
		GRID[from.y][from.x] = null
		
	prevPos = tetrimino.global_position+Vector3(direction.x, direction.y, direction.z)*CUBE_SIZE
	await tetrimino.tween_move(Vector3(direction.x, direction.y, direction.z)*CUBE_SIZE)
var curr = 0

func rotate_tetrimno(tetrimino: Tetrimino, degrees: float) -> bool:
	var axis = Vector3(0, 0, 1)
	var rotated_basis = Basis(axis, deg_to_rad(degrees))
	
	var old_positions: Array[Vector3i] = []
	var new_positions: Array[Vector3i] = []
	
	for cube in tetrimino.cubes:
		if cube is GameCube:
			var coords = to_grid_coords(cube.global_position)
			var rotated_coords = rotated_basis * Vector3(coords.x, coords.y, coords.z)
			
			if not is_pos_in_bounds(rotated_coords):
				print("veiny ah")
				return false
		
	return false

				
func _ready() -> void:
	setupGrid();
	curr = Time.get_unix_time_from_system()
	
	TICK_SPEED_TIMER.timeout.connect(func():
		if SELECTED_TETRIMINO:
			move(SELECTED_TETRIMINO, Vector3i(0,-1,0))
		
			if SELECTED_TETRIMINO and SELECTED_TETRIMINO.global_position == prevPos:
				setPiece()
		
		TICK_SPEED_TIMER.start()	
	)
	
	#TICK_SPEED_TIMER.start()
	
func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	if not SELECTED_TETRIMINO: return
	
	if Input.is_action_just_pressed("LEFT"):
		await move(SELECTED_TETRIMINO, Vector3i(-1,0,0))
		prevPos = SELECTED_TETRIMINO.global_position
	elif Input.is_action_just_pressed("RIGHT"):
		await move(SELECTED_TETRIMINO, Vector3i(1,0,0))
		prevPos = SELECTED_TETRIMINO.global_position		
	elif Input.is_action_just_pressed("ROTATE"):
		print(await rotate_tetrimno(SELECTED_TETRIMINO, -90))
		#prevPos = SELECTED_TETRIMINO.global_position
