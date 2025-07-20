@tool
class_name Grid extends Node3D

@onready var CUBE_SIZE: Vector3 =  await (InitNode.get_node("GameCube") as GameCube).get_size()
@onready var TICK_SPEED_TIMER: Timer = $TICKSPEED #seconds between each tick
var TICK_SPEED: float = 0.8

var Tetrimino_Arrangements = TetriminoArrangements.new()
var LevelInstance = Level.new()
@onready var Shapes = Tetrimino_Arrangements.shapes
@onready var GridParts = $GridParts
var tetrimino_preload = preload("res://Scenes/tetrimino.tscn")
var packed_grid_cube = preload("res://Scenes/GridBlock.tscn")
const ROWS = 20;
const COLUMNS = 10;

var lines_cleared = 0:
	set(val):
		lines_cleared = val
		UserInterface.LINES_CLEARED = lines_cleared
		
var comboScore := [40,100,300,1200]
var GRID: Array[Array] = []
@onready var SELECTED_TETRIMINO: Tetrimino

var initialPrev = Vector3(-1,-1,-1)
var prevPos = initialPrev
var prevTime = 0
var tickThreshold: int = 1
var currTicks: int = 0

var gridCoordCache: Dictionary = {}

@onready var TOP: float = self.global_position.y + (ROWS-2)*CUBE_SIZE.y*0.75
@onready var SPAWNING_POSITION: Vector3 = to_global_coords(Vector3i(3,0,0)) + Vector3(0,TOP,0)

func to_global_coords(pos: Vector3i) -> Vector3:
	return global_position+to_global_direction(pos);

func to_global_direction(pos: Vector3) -> Vector3:
	var global_coords = pos*CUBE_SIZE*0.75
	return global_coords
	
func to_grid_coords(pos: Vector3) -> Vector3i:
	
	var roundedPos = Vector3(
		(pos.x/10)*10,
		(pos.y/10)*10,
		(pos.z/10)*10
	)
	
	var cacheVal = gridCoordCache.get(roundedPos)
	if cacheVal: return cacheVal
	gridCoordCache[roundedPos] =  Vector3i(
		round((pos.x - global_position.x)/(CUBE_SIZE.x*0.75)),
		round(ROWS-1-(pos.y - global_position.y)/(CUBE_SIZE.y*0.75)),
		round((pos.z - global_position.z)/(CUBE_SIZE.z*0.75))
	)
	
	return gridCoordCache.get(roundedPos)

func setupGrid() -> void:
	GRID.resize(ROWS);
	for i in range(GRID.size()):
		GRID[i] = []
		GRID[i].resize(COLUMNS)
	for row in range(-1,ROWS+1):
		for col in range(-1,COLUMNS+1):
			var pushForward: bool = -1 in [row, col] or row == ROWS or col == COLUMNS
			var pos = Vector3(col*(CUBE_SIZE.x*0.75), (row*CUBE_SIZE.y*0.75), -154.5 if not pushForward else 0.0)
			var grid_cube: GameCube = packed_grid_cube.instantiate()
			GridParts.add_child(grid_cube)
			if pushForward: grid_cube.color = GameCube.COLORS.LIGHT_GREY
			grid_cube.position = pos

func copyColors() -> Array:
	var clrArr = []
	for color in GameCube.usableColors:
		clrArr.append(color)
	return clrArr
var currColors: Array = copyColors()
func spawn_random_piece() -> bool:
	if currColors.size() == 0: currColors = copyColors()
	var randomColor = currColors.pick_random()
	currColors.erase(randomColor)
		
	var shape = Shapes.pick_random()
	var newTetrimino: Tetrimino = tetrimino_preload.instantiate()
	newTetrimino.COLOR = randomColor as GameCube.COLORS
	newTetrimino.addShape(shape)
	
	newTetrimino.curr_origin = SPAWNING_POSITION
	var shapeCoords = newTetrimino.shape[newTetrimino.curr_idx].map(func(e):
		return to_grid_coords(SPAWNING_POSITION + Vector3(e.x, e.y, 0)*CUBE_SIZE*0.75)
	)	
	for coord in shapeCoords:
		if not_in_bounds(coord) or is_occupied(coord, null):
			return false
			
	add_child(newTetrimino)	
	newTetrimino.draw(SPAWNING_POSITION)
	SELECTED_TETRIMINO = newTetrimino
	return true
	
func set_piece() -> void:
	if not SELECTED_TETRIMINO: return
	for cube in SELECTED_TETRIMINO.cubes:
		if (cube and not cube.is_queued_for_deletion() and is_instance_valid(cube)) and cube is GameCube:
			var gridCoords = to_grid_coords(cube.global_position)
			if not not_in_bounds(gridCoords):
				GRID[gridCoords.y][gridCoords.x] = cube
	await SELECTED_TETRIMINO.blink()
	print("SPAWNING NEW ONE!")
	SELECTED_TETRIMINO = null
	
func not_in_bounds(goalCubePos: Vector3i) -> bool:
	return goalCubePos.x < 0 or goalCubePos.x >= GRID[0].size() or goalCubePos.y < 0 or goalCubePos.y >= GRID.size()

func is_occupied(goalCubePos: Vector3i, tetrimino: Tetrimino) -> bool:
	if not_in_bounds(goalCubePos):
		return true
	var cube = GRID[goalCubePos.y][goalCubePos.x]
	
	return cube != null and cube.get_parent() != tetrimino
	
func handle_rotate() -> void:
	if not SELECTED_TETRIMINO: return
	
	var nextShape = SELECTED_TETRIMINO.shape[(SELECTED_TETRIMINO.curr_idx+1)%SELECTED_TETRIMINO.shape.size()]
	var origin = SELECTED_TETRIMINO.curr_origin
	
	for part in nextShape:
		var pos = to_grid_coords(origin+ Vector3(part.x, part.y, 0)*CUBE_SIZE*0.75)
		if not_in_bounds(pos) or is_occupied(pos, SELECTED_TETRIMINO): return
	
	await get_tree().process_frame
	clearFromGrid()
	updateGrid(SELECTED_TETRIMINO)
	await SELECTED_TETRIMINO.rotate_piece()
	if SELECTED_TETRIMINO:
		SELECTED_TETRIMINO.setCubes()
		updateGrid(SELECTED_TETRIMINO)

func handle_move(global_direction: Vector3) -> bool:	
	if not SELECTED_TETRIMINO: return false
	#print("GLOBAL POS")
	#print(SELECTED_TETRIMINO.global_position)
	#print("ORIGIN: ")
	#print(to_grid_coords(SELECTED_TETRIMINO.global_position))
	#print("CUBES:")
	if SELECTED_TETRIMINO.is_transforming:
		SELECTED_TETRIMINO.cancel_tween()
		clearFromGrid()
		updateGrid(SELECTED_TETRIMINO)
	
	for cube in SELECTED_TETRIMINO.cubes:
		if not cube or cube.is_queued_for_deletion() or not is_instance_valid(cube): continue
		var goalCubePos = to_grid_coords(cube.global_position + global_direction)
		#print(goalCubePos)
		#
		var notInBounds = not_in_bounds(goalCubePos)
		var bis_occupied = is_occupied(goalCubePos, SELECTED_TETRIMINO)
		
		if notInBounds or bis_occupied:
			#if(notInBounds): print("OUT OF BOUNDS")
			#if(bis_occupied): print("OCCUPIED")
			return false
	await get_tree().process_frame
	clearFromGrid()
	SELECTED_TETRIMINO.tween_move(global_direction)
	updateGrid(SELECTED_TETRIMINO)
	return true

func clearRows() -> void:
	var currLinesCleared = 0
	clearFromGrid()
	
	var row_idx = 0
	
	while row_idx < GRID.size():
		var row = GRID[row_idx]
		if row.filter(func(e): return e != null and not e.is_queued_for_deletion() and is_instance_valid(e)).size() == COLUMNS:
			lines_cleared+=1
			currLinesCleared+=1
			for i in range(row.size()):
				row[i].queue_free()
				row[i] = null
			for aboveRow in range(row_idx-1, -1, -1):
				for column in range(GRID[aboveRow].size()):
					var cube = GRID[aboveRow][column]
					if cube == null or cube.is_queued_for_deletion() or not is_instance_valid(cube): continue
					GRID[aboveRow][column] = null
					GRID[aboveRow+1][column] = cube
					cube.position -= Vector3(0, CUBE_SIZE.y*0.75, 0)
		else:
			row_idx+=1
	for tetrimino in get_children():
		if tetrimino is Tetrimino and tetrimino.get_child_count() == 0:
				tetrimino.queue_free()
	if currLinesCleared > 0:
		UserInterface.SCORE += comboScore[currLinesCleared-1]

func clearFromGrid() -> void:
	for row_idx in range(GRID.size()):
		for col_idx in range(GRID[row_idx].size()):
			var cube = GRID[row_idx][col_idx]
			if cube == null: continue
			if cube is GameCube:
				if cube.is_queued_for_deletion() or not is_instance_valid(cube):
					GRID[row_idx][col_idx] = null
					continue
				var coords = to_grid_coords(cube.global_position)
				
				#print("GRID COORDS: %v" % coords)
				#print("DESIRED: %v" % Vector3i(col_idx, row_idx, 0))
				
				if coords.y != row_idx or coords.x != col_idx:
					GRID[row_idx][col_idx] = null

func updateGrid(tetrimino: Tetrimino) -> void:
	#print(GRID)
	#print("\n\n")
	if not tetrimino: return
	tetrimino.setCubes()
	tetrimino.last_coords.clear()
	for cube in tetrimino.cubes:
		if cube is GameCube and not cube.is_queued_for_deletion():
			var coords = to_grid_coords(cube.global_position)
			tetrimino.last_coords.append(coords)
			GRID[coords.y][coords.x] = cube

func get_level() -> int:
	return lines_cleared/5

func adjust_time(level: int) -> void:
	if(level == LevelInstance.KILLEVEL):
		TICK_SPEED = LevelInstance.KILLTIME
		return
	if(level >= LevelInstance.LevelArray.size()):
		TICK_SPEED = LevelInstance.LevelArray[LevelInstance.LevelArray.size()-1]
		return
	
	TICK_SPEED = LevelInstance.LevelArray[level]	

func prettyPrint(grid: Array[Array]) -> String:
	var s = ""
	for row in grid:
		for col in row:
			if col == null: s+="."
			else: s+="#"
		s+='\n'
	return s 

func _ready() -> void:
	TICK_SPEED_TIMER.wait_time = 0.8
	#print(SPAWNING_POSITION)
	setupGrid()
	#SELECTED_TETRIMINO.addShape(Tetrimino_Arrangements.j)
	#SELECTED_TETRIMINO.draw(Vector3(0,0,0))
	TICK_SPEED_TIMER.timeout.connect(func():
		#print("TICK")
		print(prettyPrint(GRID))
		
		if SELECTED_TETRIMINO == null:
			clearRows()
			var suc = spawn_random_piece()
			if not suc: (get_parent() as GameScene).resetGame()
		var res: bool = await handle_move(to_global_direction(Vector3(0,-1,0)))
		if not res: 
			set_piece()

		
		var lvl = get_level()
		UserInterface.LEVEL = lvl
		adjust_time(lvl)
		
		TICK_SPEED_TIMER.wait_time = TICK_SPEED
		TICK_SPEED_TIMER.start()
	)
	
	TICK_SPEED_TIMER.start()

var is_moving = false

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or is_moving: return
	
	if Input.is_action_just_pressed("RIGHT") and SELECTED_TETRIMINO:
		is_moving = true
		await handle_move(to_global_direction(Vector3(1,0,0)))
		is_moving = false
	elif Input.is_action_just_pressed("LEFT") and SELECTED_TETRIMINO:
		is_moving = true	
		await handle_move(to_global_direction(Vector3(-1,0,0)))
		is_moving = false
	elif Input.is_action_just_pressed("ui_down") and SELECTED_TETRIMINO:
		is_moving = true
		await handle_move(to_global_direction(Vector3(0,-1,0)))
		is_moving = false
	elif Input.is_action_just_pressed("ROTATE") and SELECTED_TETRIMINO:
		await handle_rotate()
	#print("WORLD COORDS: %v, GRID COORDS: %v" % [SELECTED_TETRIMINO.curr_origin, to_grid_coords(SELECTED_TETRIMINO.curr_origin)])
