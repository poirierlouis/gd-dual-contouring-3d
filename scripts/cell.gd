class_name Cell

const CELL_OFFSET: Array[Vector3] = [
	Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(1, 0, 1),
	Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(0, 1, 1), Vector3(1, 1, 1),
]

const CROSS_EDGES: Array[Array] = [
	[0, 1], [0, 2], [1, 3], [2, 3],
	
	[4, 5], [4, 6], [5, 7], [6, 7],
	
	[0, 4], [1, 5], [2, 6], [3, 7],
]

var position: Vector3
var grid_position: Vector3
var grid_scale: Vector3

#    4---------5
#   /|        /|
#  / |       / |        Y
# 6---------7  |        |
# |  0------|--1		+---X
# | /       | /        /
# |/        |/        Z
# 2---------3
var voxels: Array[float] = []

var offsets: Array[Vector3] = []

var edges: Array = []
var edges_count := 0

var vertices: Array[Vector3] = []

func _init(position: Vector3, grid_position: Vector3, grid_scale: Vector3):
	self.position = position
	self.grid_position = grid_position
	self.grid_scale = grid_scale
	self.offsets.resize(8)
	self.voxels.resize(8)
	self.edges.resize(12)
	self.edges.fill(null)

# Compute voxels of [this] cell using [iso_fn] to get density.
func compute_voxels(iso_fn: Callable) -> void:
	for i in 8:
		offsets[i] = position + CELL_OFFSET[i]
		voxels[i] = iso_fn.call(
			grid_position.x * grid_scale.x + offsets[i].x * grid_scale.x,
			grid_position.y * grid_scale.y + offsets[i].y * grid_scale.y,
			grid_position.z * grid_scale.z + offsets[i].z * grid_scale.z
		)

# Compute sign changes between voxels (along edges).
#
# Return true when at least three edges are crossed.
func compute_edges() -> bool:
	for i in 12:
		var indices := CROSS_EDGES[i]
		
		if signf(voxels[indices[0]]) - signf(voxels[indices[1]]) != 0.0:
			edges[i] = compute_edge(indices[0], indices[1])
			edges_count += 1
	return edges_count >= 3

# Compute surface position on an edge between voxels [ai] and [bi].
func compute_edge(ai: int, bi: int) -> Vector3:
	var a := offsets[ai]
	var b := offsets[bi]
	var t := -voxels[ai] / (voxels[bi] - voxels[ai])
	
	return a + t * (b - a)

# Compute vertex(ices) position of [this] cell based on [edges] crossing.
func compute_vertex() -> void:
	var sides: Array = edges.filter(func(edge): return edge != null)
	var vertex: Vector3 = sides.reduce(func(a, b):
		return Cell.get_centroid(a, b)
	)
#	if sides.size() > 3:
		# TBD: non-manifold to manifold
#		print("<cell at='%s' crossing-edges='%d' />" % [position, sides.size()])
#		return
#	var a := Cell.get_centroid(sides[0], sides[1])
#	var b := Cell.get_centroid(sides[1], sides[2])
#	var vertex := Cell.get_centroid(a, b)
#
	vertices.push_back(vertex)

func get_vertex() -> Vector3:
	return vertices[0]

#    +---------+
#   /|4       /|
#  / |    1  / |        Y
# +---------+ 3|        |
# |2 +------|--+		+---X
# | / 0     | /        /
# |/       5|/        Z
# +---------+
func get_faces() -> Array[Dictionary]:
	var faces: Array[Dictionary] = []
	
	if edges[11] != null:
		faces.append({
			"reverse": true,
			"flip": voxels[3] >= 0.0,
			"vertices": [Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(1, 0, 1)]
		})
	if edges[6] != null:
		faces.append({
			"reverse": false,
			"flip": voxels[5] < 0.0,
			"vertices": [Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(1, 1, 0)]
		})
	if edges[7] != null:
		faces.append({
			"reverse": false,
			"flip": voxels[6] >= 0.0,
			"vertices": [Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(0, 1, 1)]
		})
	return faces

# Compute center point between [a] and [b].
static func get_centroid(a: Vector3, b: Vector3) -> Vector3:
	return (a + b) / 2.0
