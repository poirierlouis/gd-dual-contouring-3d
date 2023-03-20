class_name Terrain3D

extends Node3D

var ChunkScene = preload("res://scenes/terrain_chunk_3d.tscn")

#var ChunkMaterial = load("res://assets/chunk_material.tres")
var PointMaterial = load("res://assets/point_material.tres")

@export var chunk_size := Vector3(32.0, 32.0, 32.0)
@export var chunk_scale := Vector3(8.0, 8.0, 8.0)

var noise := FastNoiseLite.new()

var chunks: Array[Dictionary] = []

var thread := Thread.new()

func _init():
	noise.seed = 1953754538#randi()#0
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.001
	print("seed: %d" % noise.seed)
	for y in range(-1, 0 + 1):
		for z in range(0, 1 + 1):
			for x in range(0, 1 + 1):
				chunks.push_back({
					"scene": ChunkScene.instantiate(),
					"position": Vector3i(x, y, z),
				})

func _ready():
	thread.start(_run)

func _exit_tree():
	thread.wait_to_finish()

func _run():
	for chunk_data in chunks:
		generate_chunk(chunk_data)

func generate_chunk(chunk_data: Dictionary) -> void:
	var chunk: TerrainChunk3D = chunk_data["scene"]
	var grid_position: Vector3i = chunk_data["position"]
	
	create_chunk(chunk, grid_position)
	call_deferred("add_child", chunk)

func create_chunk(chunk: TerrainChunk3D, grid_position: Vector3i) -> void:
	chunk.noise = noise
	chunk.grid_size = chunk_size
	chunk.grid_scale = chunk_scale
	chunk.position = Vector3(grid_position) * chunk_size
	chunk.material = PointMaterial
	chunk.build()
