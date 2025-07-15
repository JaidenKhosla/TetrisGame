@tool
class_name GameCube 
extends CharacterBody3D

enum COLORS {
	RED,
	BLUE,
	ORANGE,
	YELLOW,
	GREEN,
	CYAN,
	PURPLE,
	WHITE,
	GREY,
	LIGHT_GREY
}

const colorArray = [
	Color.RED, #RED
	Color.BLUE, #BLUE
	Color.ORANGE, #ORANGE
	Color.YELLOW, #YELLOW
	Color.LIME_GREEN, #GREEN
	Color.CYAN, #CYAN
	Color.REBECCA_PURPLE, #PURPLE
	Color.WHITE, #WHITE
	Color.DIM_GRAY, #GRAY
	Color.LIGHT_GRAY 
]
@onready var model: MeshInstance3D = $model;
@export var color: COLORS:
	set(clr):
		color = clr
		updateMaterial(colorArray[color])

func get_size() -> Vector3:
	if not model:
		await self.ready
		await model.ready
	return model.get_aabb().size;

func updateMaterial(color: Color) -> void:
	if model:
		var material = StandardMaterial3D.new()
		material.albedo_color = color
		model.material_override = material
		model.notify_property_list_changed()
		model.update_gizmos()

func is_sibling(potentialSibling: GameCube) -> bool:
	return self.get_parent() == potentialSibling.get_parent()

func _ready() -> void:
	updateMaterial(colorArray[color])
