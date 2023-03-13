class_name TerrainChunk3D

extends Node3D

#var mesh := MeshInstance3D.new()
#var tool := SurfaceTool.new()

var points := MultiMeshInstance3D.new()

var noise: FastNoiseLite
var material: StandardMaterial3D

var grid_size: Vector3
var grid_scale: Vector3

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
					data[x + z * grid_size.x + y * grid_size.x * grid_size.z] = cell
	var cells := data.filter(func(cell): return cell != null)
	var mesh := SphereMesh.new()
	
	mesh.surface_set_material(0, material)
	mesh.radius = 0.1
	mesh.height = 2 * mesh.radius
	
	points.multimesh = MultiMesh.new()
	points.multimesh.mesh = mesh
	points.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	points.multimesh.instance_count = cells.size()
	points.multimesh.visible_instance_count = cells.size()
	for i in cells.size():
		points.multimesh.set_instance_transform(i, Transform3D(Basis(), cells[i].get_vertex()))
	add_child(points)
#	add_child(mesh)
