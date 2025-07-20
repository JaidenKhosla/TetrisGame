@tool

class_name Tetrimino extends Node3D

@onready var cubes: Array[Node]

var CURRTWEEN: Tween
var CURRGOAL: Vector3

func setCubes():
	cubes = self.get_children().filter(func(e):
		return e is GameCube and is_instance_valid(e) and not e.is_queued_for_deletion();
	)

var cube_preload = preload("res://Scenes/game_cube.tscn")
@onready var CUBE_SIZE: Vector3 =  await (InitNode.get_node("GameCube") as GameCube).get_size()
const colorEnum = GameCube.COLORS

var is_transforming: bool = false

var shape: Array
var curr_idx = 0
var curr_origin: Vector3 = Vector3.ZERO

var last_coords: Array[Vector3i] = []

func addShape(new_shape: Array):
	shape = new_shape

@export var COLOR: colorEnum:
	set(clr):
		COLOR = clr
		setCubes()
		for cube in cubes:
			if cube is GameCube:
				cube.updateMaterial(GameCube.colorArray[COLOR])

var isRotating = false

func draw(origin: Vector3):
	curr_origin = origin
	global_position = origin
	print("DRAW ORIGIN: %v" % curr_origin)
	var bitmap = shape[curr_idx]
	for pos in bitmap:
		var newCube: GameCube = cube_preload.instantiate()
		add_child(newCube)
		newCube.color = COLOR
		newCube.position = Vector3(pos.x, pos.y, 0)*CUBE_SIZE*0.75
	#await get_tree().process_frame
	setCubes()
	
func rotate_piece():
	curr_idx = (curr_idx+1)%shape.size()
	clear()
	draw(curr_origin)
	
func clear():
	for child in get_children():
		if child is GameCube:
			child.queue_free()
	cubes.clear()

	await get_tree().process_frame
func tween_rotate(deg: float) -> int:
	if isRotating: return 0
	isRotating = true
	var goal = rotation.z + deg_to_rad(deg);
	await create_tween().tween_property(self, "rotation:z", goal, 0.25).finished
	isRotating = false
	return 1

func cancel_tween() -> void:
	if is_transforming and CURRTWEEN and CURRTWEEN.is_running():
		CURRTWEEN.kill()
		global_position = CURRGOAL
		is_transforming = false

func tween_move(direction: Vector3) -> int:
	
	cancel_tween()
		
	is_transforming = true
	CURRGOAL = global_position+direction
	curr_origin = CURRGOAL
	
	var innerTween = create_tween()
	innerTween.tween_property(self, "global_position", CURRGOAL, 0.25)
	CURRTWEEN = innerTween
	innerTween.finished.connect(func():
		is_transforming = false	
	)
	return 1

func blink() -> void:
	var prevClr = COLOR
	COLOR = colorEnum.WHITE
	var timer = get_tree().create_timer(0.35)
	timer.timeout.connect(func():	
		COLOR = prevClr
	)
	
