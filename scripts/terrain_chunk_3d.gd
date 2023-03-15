@tool

class_name TerrainChunk3D

extends Node3D

#var mesh := MeshInstance3D.new()
#var tool := SurfaceTool.new()

var points := MultiMeshInstance3D.new()

@export var noise: FastNoiseLite
@export var material: StandardMaterial3D

@export var grid_size: Vector3:
	set(value):
		if value != grid_size:
			grid_size = value
			on_property_changed()

@export var grid_scale: Vector3:
	set(value):
		if value != grid_scale:
			grid_scale = value
			on_property_changed()

# Editor only
var _thread: Thread
var _semaphore: Semaphore
var _running: bool

func _init():
	if Engine.is_editor_hint():
		_thread = Thread.new()
		_semaphore = Semaphore.new()
		_running = false
	var mesh := SphereMesh.new()
	
	mesh.radius = 0.2
	mesh.height = 2 * mesh.radius
	
	points.multimesh = MultiMesh.new()
	points.multimesh.mesh = mesh
	points.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	add_child(points)

func _ready():
	if Engine.is_editor_hint():
		noise.changed.connect(on_property_changed)
		_running = true
		_thread.start(on_rebuild)
		_semaphore.post()
	points.multimesh.mesh.surface_set_material(0, material)
#	add_child(mesh)

func _exit_tree():
	if Engine.is_editor_hint():
		_running = false
		_semaphore.post()
		_thread.wait_to_finish()

# Editor only
# 
# Rebuild chunk on property changed event.
func on_property_changed() -> void:
	if not Engine.is_editor_hint():
		return
	_semaphore.post()

# Editor only
#
# Thread waiting on a trigger event to rebuild, without blocking.
func on_rebuild() -> void:
	while true:
		_semaphore.wait()
		if !_running:
			return
		build()

func build() -> void:
	var data: Array[Cell] = []
	
	data.resize(int(grid_size.x * grid_size.y * grid_size.z))
	data.fill(null)
	for y in grid_size.y:
		for z in grid_size.z:
			for x in grid_size.x:
				var cell_position := Vector3(x, y, z)
				var cell := Cell.new(cell_position, position, grid_scale)
				
				cell.compute_voxels(noise.get_noise_3d)
				var is_crossing := cell.compute_edges()
				
				if !is_crossing:
					continue
				cell.compute_vertex()
				if !cell.vertices.is_empty():
					var index := get_cell_index(x, y, z)
					
					data[index] = cell
	var cells := data.filter(func(cell): return cell != null)

	points.multimesh.instance_count = cells.size()
	points.multimesh.visible_instance_count = cells.size()
	for i in cells.size():
		points.multimesh.set_instance_transform(i, Transform3D(Basis(), cells[i].get_vertex()))

func get_cell_index(x: int, y: int, z: int) -> int:
	return x + z * grid_size.x + y * grid_size.x * grid_size.z
