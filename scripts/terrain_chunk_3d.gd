@tool

class_name TerrainChunk3D

extends Node3D

const TRIANGLE_INDICES := [
	[[1, 2], [3, 2]],
	[[2, 1], [2, 3]],
]

var mesh := MeshInstance3D.new()
var tool := SurfaceTool.new()

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

var max_grid_size_index: int:
	get:
		return int((grid_size.x + 2) * (grid_size.z + 2) * (grid_size.y + 2))

# Editor only
var _thread: Thread
var _semaphore: Semaphore
var _running: bool

func _init():
	if Engine.is_editor_hint():
		_thread = Thread.new()
		_semaphore = Semaphore.new()
		_running = false
	var sphere := SphereMesh.new()
	
	sphere.radius = 0.2
	sphere.height = 2 * sphere.radius
	sphere.radial_segments = 16
	sphere.rings = roundi(sphere.radial_segments / 2.0)
	
	points.name = "Vertices"
	points.multimesh = MultiMesh.new()
	points.multimesh.mesh = sphere
	points.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	add_child(points)
	
	mesh.name = "Mesh"
	add_child(mesh)

func _ready():
	if Engine.is_editor_hint():
		noise.changed.connect(on_property_changed)
		_running = true
		_thread.start(on_rebuild)
		_semaphore.post()
	points.multimesh.mesh.surface_set_material(0, material)

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

# Show / hide points (vertices per voxel).
func toggle_points() -> void:
	if points.is_inside_tree():
		remove_child(points)
	else:
		add_child(points)

func build() -> void:
	var data: Array[Cell] = []
	
	data.resize(int((grid_size.x + 2) * (grid_size.y + 2) * (grid_size.z + 2)))
	data.fill(null)
	for y in range(-1, grid_size.y + 1):
		for z in range(-1, grid_size.z + 1):
			for x in range(-1, grid_size.x + 1):
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
	var vertices := PackedVector3Array()
	
	for y in grid_size.y:
		for z in grid_size.z:
			for x in grid_size.x:
				var index := get_cell_index(x, y, z)
				var cell := data[index]
				
				if cell == null:
					continue
				var faces: Array[Dictionary] = cell.get_faces()
				
				for face in faces:
					var face_vertices: Array = face["vertices"]
					var quad: Array[Vector3] = [cell.get_vertex()]
					
					for vertex in face_vertices:
						var cell_index := get_cell_index(x + vertex.x, y + vertex.y, z + vertex.z)
						
						if cell_index == -1:
							break
						var adjacent := data[cell_index]
						
						if adjacent != null:
							quad.push_back(adjacent.get_vertex())
					if quad.size() != 4:
						continue
					var flip: int = 0 if !face["flip"] else 1
					
					vertices.push_back(quad[0])
					vertices.push_back(quad[TRIANGLE_INDICES[flip][0][0]])
					vertices.push_back(quad[TRIANGLE_INDICES[flip][0][1]])
					
					vertices.push_back(quad[1])
					vertices.push_back(quad[TRIANGLE_INDICES[flip][1][0]])
					vertices.push_back(quad[TRIANGLE_INDICES[flip][1][1]])
	
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in vertices:
		tool.add_vertex(vertex)
	tool.generate_normals()
	mesh.mesh = tool.commit()
	
	var cells := data.filter(func(cell): return cell != null)

	points.multimesh.instance_count = cells.size()
	points.multimesh.visible_instance_count = cells.size()
	for i in cells.size():
		points.multimesh.set_instance_transform(i, Transform3D(Basis(), cells[i].get_vertex()))

# Get index number at (x, y, z) position in buffer.
#
# Returns an index number, -1 when out of bounds.
func get_cell_index(x: float, y: float, z: float) -> int:
	if x < 0 || y < 0 || z < 0 || x >= grid_size.x + 2 || y >= grid_size.y + 2 || z >= grid_size.z + 2:
		return -1
	var index := int(x + z * (grid_size.x + 2) + y * (grid_size.x + 2) * (grid_size.z + 2))
	
	if index < 0 || index >= max_grid_size_index:
		return -1
	return index
