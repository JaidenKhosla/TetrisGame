@tool

class_name Tetrimino extends Node3D

@onready var cubes: Array[Node] = self.get_children().filter(func(e):
	return e is GameCube;
)

const colorEnum = GameCube.COLORS

@export var COLOR: colorEnum:
	set(clr):
		COLOR = clr
		for cube in cubes:
			if cube is GameCube:
				cube.updateMaterial(GameCube.colorArray[COLOR])

func tween_rotate(deg: float) -> int:
	var goal = rotation.z + deg_to_rad(deg);
	await create_tween().tween_property(self, "rotation:z", goal, 0.25).finished
	return 1
	
func tween_move(direction: Vector3) -> int:
	var goal = global_position+direction;
	await create_tween().tween_property(self, "global_position", goal, 0.25).finished
	return 1
	
