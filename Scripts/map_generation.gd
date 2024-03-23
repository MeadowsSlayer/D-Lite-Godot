extends Node2D

var noise_map = FastNoiseLite.new()
var rand_gen = RandomNumberGenerator.new()
var altitude_noise_layer = {}
var map_size = Vector2(24, 24)

@export var tile_map : TileMap
@export var main     : Node2D

@export var alt_freq : float = 0.1
@export var oct : int = 4
@export var lac : int = 8
@export var gain : float = 0.5
@export var amplitude : float = 1.0

func _ready():
	altitude_noise_layer = generate_noise(rand_gen.randi(), alt_freq, oct, lac, gain)
	generate_map(map_size.x, map_size.y)
	main.start()

func generate_noise(noise_seed, frequency, octaves, lacunarity, gain):
	noise_map.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise_map.seed = noise_seed
	noise_map.frequency = frequency
	noise_map.fractal_octaves = octaves
	noise_map.fractal_lacunarity = lacunarity
	noise_map.fractal_gain = gain

	var grid = {}
	for x in map_size.x:
		for y in map_size.y:
			var rand = abs(noise_map.get_noise_2d(x,y) * 2 - 1 )
			grid[Vector2i(x, y)] = rand
	return grid

func generate_map(width, height):
	for x in width:
		for y in height:
			var pos = Vector2i(x, y)
			var alt = altitude_noise_layer[pos]
			var tile = get_random_tile(alt)
			set_nodes_values(tile, pos)
			tile_map.set_cell(0, pos, 1, tile, 0)

func get_random_tile(alt : float):
	if alt <= 0.8:
		return Vector2i(0,0)
	elif alt > 0.8 and alt <= 1.0:
		return Vector2i(rand_gen.randi_range(1, 2), 1)
	elif alt > 1.0 and alt <= 1.25:
		return Vector2i(3,1)
	elif alt > 1.25 and alt <= 1.5:
		return Vector2i(rand_gen.randi_range(1, 2), 0)
	elif alt > 1.5 and alt <= 1.75:
		return Vector2i(rand_gen.randi_range(1, 2), 2)
	else:
		return Vector2i(3,0)
	return Vector2i(0,0)
	pass

func set_nodes_values(tile : Vector2i, pos : Vector2i):
	var x_offset = 0 if pos.y % 2 == 0 else 32
	var top_node    = (pos - Vector2i(1, 1) + Vector2i(pos.x, 0)) * Vector2i(32, 32) - Vector2i(-x_offset, 16)
	var bottom_node = (pos - Vector2i(1, 1) + Vector2i(pos.x, 0)) * Vector2i(32, 32) + Vector2i(x_offset, 16)
	var top_node_weight    : float
	var bottom_node_weight : float
	match tile:
		Vector2i(0, 0):
			top_node_weight = 0
			bottom_node_weight = 0
		Vector2i(1, 0):
			top_node_weight = INF
			bottom_node_weight = 0
		Vector2i(2, 0):
			top_node_weight = 0
			bottom_node_weight = INF
		Vector2i(3, 0):
			top_node_weight = INF
			bottom_node_weight = INF
		Vector2i(1, 1):
			top_node_weight = 1
			bottom_node_weight = 0
		Vector2i(2, 1):
			top_node_weight = 0
			bottom_node_weight = 1
		Vector2i(3, 1):
			top_node_weight = 1
			bottom_node_weight = 1
		Vector2i(1, 2):
			top_node_weight = 1
			bottom_node_weight = INF
		Vector2i(2, 2):
			top_node_weight = INF
			bottom_node_weight = 1
	if main.graph.map.has(Vector2(top_node)):
		main.graph.nodes_array[main.graph.map[Vector2(top_node)]].weight = top_node_weight
	if main.graph.map.has(Vector2(bottom_node)):
		main.graph.nodes_array[main.graph.map[Vector2(bottom_node)]].weight = bottom_node_weight
	pass
