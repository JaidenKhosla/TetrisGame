class_name GameScene extends Node3D

@onready var Camera: Camera3D = $Camera3D
@onready var currGrid: Grid = $Grid

var GridInstance = preload("res://Scenes/Grid.tscn")

const CENTER = Vector3i(0,0,0)
const RADIUS = 585

var angle = 270
var step = 11;


#func getPosFromAngle(angl: int) -> Vector3:
	#return Vector3(RADIUS * cos(deg_to_rad(angl)), Camera.global_position.y, RADIUS * sin(deg_to_rad(angl)))
	#Camera.look_at(CENTER)
	#
func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	var DIRECTION = Vector3.ZERO
	
	if Input.is_action_pressed("MOVE_CAMERA_RIGHT"):
		DIRECTION += Camera.transform.basis.x
	if Input.is_action_pressed("MOVE_CAMERA_LEFT"):
		DIRECTION -= Camera.transform.basis.x
	if Input.is_action_pressed("MOVE_CAMERA_FORWARD"):
		DIRECTION -= Camera.transform.basis.z
	if Input.is_action_pressed("MOVE_CAMERA_BACKWARD"):
		DIRECTION += Camera.transform.basis.z
	
	DIRECTION = DIRECTION.normalized()
	
	Camera.global_position+=DIRECTION*step

func resetGame():
	
	UserInterface.GameOver.show()
	await get_tree().create_timer(3).timeout
	UserInterface.GameOver.hide()
	UserInterface.LINES_CLEARED = 0
	UserInterface.SCORE = 0
	UserInterface.LEVEL = 0
	currGrid.queue_free()
	currGrid = GridInstance.instantiate()
	add_child(currGrid)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("PAUSE"):
		get_tree().paused = !get_tree().paused
		UserInterface.PAUSED = !UserInterface.PAUSED
	elif Input.is_action_just_pressed("RESET"):
		resetGame()
	
