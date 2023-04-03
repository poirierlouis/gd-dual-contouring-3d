@tool

class_name Cell3D

extends Node3D

var VoxelAirMaterial: StandardMaterial3D = load("res://assets/voxel_air_material.tres")
var VoxelSolidMaterial: StandardMaterial3D = load("res://assets/voxel_solid_material.tres")

var EdgeEmptyMaterial: StandardMaterial3D = load("res://assets/edge_empty_material.tres")
var EdgeCrossingMaterial: StandardMaterial3D = load("res://assets/edge_crossing_material.tres")

@export var voxels: Array[bool] = [false, false, false, false, false, false, false, false]:
	set(value):
		voxels = value
		if Engine.is_editor_hint():
			update_cell()
			screenshot()

@export var with_screenshot := false

var cubes: Array[MeshInstance3D] = []
var edges: Array[MeshInstance3D] = []

func _ready():
	for i in 8:
		cubes.push_back(get_node("%d" % i))
	edges.append_array([
		get_node("(0, 1)") as MeshInstance3D,
		get_node("(0, 2)") as MeshInstance3D,
		get_node("(1, 3)") as MeshInstance3D,
		get_node("(2, 3)") as MeshInstance3D,
		
		get_node("(4, 5)") as MeshInstance3D,
		get_node("(4, 6)") as MeshInstance3D,
		get_node("(5, 7)") as MeshInstance3D,
		get_node("(6, 7)") as MeshInstance3D,
		
		get_node("(0, 4)") as MeshInstance3D,
		get_node("(1, 5)") as MeshInstance3D,
		get_node("(2, 6)") as MeshInstance3D,
		get_node("(3, 7)") as MeshInstance3D,
	])
	update_cell()

func screenshot():
	if not with_screenshot:
		return
	var viewport := get_viewport()
	
	await RenderingServer.frame_post_draw
	var image := viewport.get_window().get_texture().get_image()
	var file_name: String = ""
	
	for i in cubes.size():
		file_name += "1" if voxels[i] else "0"
	image = image.get_region(Rect2i(650, 224, 624, 510))
	image.save_png("user://screenshot_%s.png" % file_name)

func build(cell: Cell) -> void:
	position = cell.position
	scale /= 5.0
	for i in 8:
		voxels[i] = signf(cell.voxels[i]) >= 0.0
	update_cell()

func update_cell():
	for i in cubes.size():
		var material: StandardMaterial3D = VoxelSolidMaterial if voxels[i] else VoxelAirMaterial
		
		cubes[i].set_surface_override_material(0, material)
	for edge in edges:
		var a := edge.name.substr(1, 1).to_int()
		var b := edge.name.substr(4, 1).to_int()
		var is_crossing := voxels[a] != voxels[b]
		var material: StandardMaterial3D = EdgeCrossingMaterial if is_crossing else EdgeEmptyMaterial
		
		edge.set_surface_override_material(0, material)
