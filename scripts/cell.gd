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

const A := 0
const B := 1
const C := 2
const D := 3
const E := 4
const F := 5
const G := 6
const H := 7
const I := 8
const J := 9
const K := 10
const L := 11

const ADJACENT_EDGES: Array[Array] = [
	[B, C, I, J, D, E], # Edge A (0)
	[A, D, K, I, C, F], # Edge B (1)
	[A, D, J, L, B, G], # Edge C (2)
	[B, C, K, L, A, H], # Edge D (3)
	[F, G, I, J, H, A], # Edge E (4)
	[E, H, I, K, G, B], # Edge F (5)
	[E, H, J, L, F, C], # Edge G (6)
	[F, G, K, L, E, D], # Edge H (7)
	[A, B, E, F, J, K], # Edge I (8)
	[A, C, E, G, I, L], # Edge J (9)
	[B, D, F, H, I, L], # Edge K (10)
	[C, D, G, H, J, K], # Edge L (11)
]

var position: Vector3
var grid_position: Vector3
var grid_scale: Vector3

#     4-----E-----5
#    /|          /|
#   F I         G J
#  /  |        /  |        Y
# 6-----H-----7   |        |
# |   0-----A-|---1		   +---X
# K  /        L  /        /
# | B         | C        Z
# |/          |/
# 2-----D-----3
var voxels: Array[float] = []

var offsets: Array[Vector3] = []

var edges: Array = []

var vertices: Array[Vector3] = []
var normals: Array[Vector3] = []
var normals_count: int = 0

func _init(p_position: Vector3, p_grid_position: Vector3, p_grid_scale: Vector3):
	self.position = p_position
	self.grid_position = p_grid_position
	self.grid_scale = p_grid_scale
	self.offsets.resize(8)
	self.voxels.resize(8)
	self.edges.resize(12)
	self.edges.fill(null)

# Compute voxels of [this] cell using [iso_fn] to get density.
#
# Returns true when [this] cell is crossing iso-surface.
func compute_voxels(iso_fn: Callable) -> bool:
	var crossing_mask := 0
	
	for i in 8:
		offsets[i] = position + CELL_OFFSET[i]
		voxels[i] = iso_fn.call(
			grid_position.x * grid_scale.x + offsets[i].x * grid_scale.x,
			grid_position.y * grid_scale.y + offsets[i].y * grid_scale.y,
			grid_position.z * grid_scale.z + offsets[i].z * grid_scale.z
		)
		if voxels[i] >= 0.0:
			crossing_mask |= (1 << i)
	return !(crossing_mask == 0 || crossing_mask == 255)

# Compute sign changes between voxels (along edges).
func compute_edges() -> void:
	for i in 12:
		var indices := CROSS_EDGES[i]
		
		if signf(voxels[indices[0]]) - signf(voxels[indices[1]]) != 0.0:
			edges[i] = compute_edge(indices[0], indices[1])

# Compute surface position on an edge between voxels [ai] and [bi].
func compute_edge(ai: int, bi: int) -> Vector3:
	var a := offsets[ai]
	var b := offsets[bi]
	var t := -voxels[ai] / (voxels[bi] - voxels[ai])
	
	return a + t * (b - a)

# Compute vertex(ices) position of [this] cell based on [edges] crossing.
func compute_vertex() -> void:
	var sides: Array = edges.filter(func(edge): return edge != null)
	var vertex := Vector3.ZERO
	
	for side in sides:
		vertex += side
	vertex /= sides.size()
	vertices.push_back(vertex)

# Sum [normal] with previous one.
func add_normal(normal: Vector3) -> void:
	if normals.is_empty():
		normals.push_back(normal)
		return
	normals[0] += normal
	normals_count += 1

func get_vertex() -> Vector3:
	return vertices[0]

func compute_normal() -> Vector3:
	return (normals[0] / normals_count).normalized()

#     4-----E-----5
#    /|          /|
#   F I         G J
#  /  |        /  |        Y
# 6-----H-----7   |        |
# |   0-----A-|---1		   +---X
# K  /        L  /        /
# | B         | C        Z
# |/          |/
# 2-----D-----3
func get_faces() -> Array[Dictionary]:
	var faces: Array[Dictionary] = []
	
	if edges[L] != null:
		faces.append({
			"flip": voxels[3] >= 0.0,
			"vertices": [Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(1, 0, 1)]
		})
	if edges[G] != null:
		faces.append({
			"flip": voxels[5] < 0.0,
			"vertices": [Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(1, 1, 0)]
		})
	if edges[H] != null:
		faces.append({
			"flip": voxels[6] >= 0.0,
			"vertices": [Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(0, 1, 1)]
		})
	return faces

# Compute center point between [a] and [b].
static func get_centroid(a: Vector3, b: Vector3) -> Vector3:
	return (a + b) / 2.0
