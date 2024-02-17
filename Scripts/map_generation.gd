extends Node2D

var noise_map = FastNoiseLite.new()
var rand_gen = RandomNumberGenerator.new()
var altitude_noise_layer = {}
var map_size = Vector2(24, 24)

@onready var tile_map = $TileMap

@export var alt_freq : float = 0.1
@export var oct : int = 4
@export var lac : int = 8
@export var gain : float = 0.5
@export var amplitude : float = 1.0

func _ready():
	altitude_noise_layer = generate_noise(rand_gen.randi(), alt_freq, oct, lac, gain)
	generate_map(map_size.x, map_size.y)

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
			if alt <= 0.8:
				tile_map.set_cell(0, pos, 1, Vector2i(0,0), 0)
			elif alt > 0.8 and alt <= 1.0:
				tile_map.set_cell(0, pos, 1, Vector2i(rand_gen.randi_range(1, 2), 1), 0)
			elif alt > 1.0 and alt <= 1.25:
				tile_map.set_cell(0, pos, 1, Vector2i(3,1), 0)
			elif alt > 1.25 and alt <= 1.5:
				tile_map.set_cell(0, pos, 1, Vector2i(rand_gen.randi_range(1, 2), 0), 0)
			elif alt > 1.5 and alt <= 1.75:
				tile_map.set_cell(0, pos, 1, Vector2i(rand_gen.randi_range(1, 2), 2), 0)
			else:
				tile_map.set_cell(0, pos, 1, Vector2i(3,0), 0)
