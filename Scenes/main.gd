extends Node2D

@onready var map = $Map
@onready var robot = $Robot
@onready var goal = $Goal

var robot_pos = 0
var goal_pos = 0
var limit_x_graph = [32, 1120]
var limit_y_graph = [16, 624]
var limit_x_map = [32, 1120]
var limit_y_map = [32, 608]
var paths_possible = []
var graph = {}
var map_grid = {}
var move_directions = {
	"right": Vector2(32, 0),
	"left": Vector2(-32, 0),
	"up": Vector2(0, -32),
	"down": Vector2(0, 32)}
var rand_gen = RandomNumberGenerator.new()

func _ready():
	rand_gen.randomize()
	init_graph()
	init_map()
	while robot_pos == goal_pos:
		var random_key = graph.keys()[rand_gen.randi_range(0, graph.size() - 1)]
		while check_key(random_key) == false:
			random_key = graph.keys()[rand_gen.randi_range(0, graph.size() - 1)]
		robot_pos = random_key
		random_key = graph.keys()[rand_gen.randi_range(0, graph.size() - 1)]
		while check_key(random_key) == false:
			random_key = graph.keys()[rand_gen.randi_range(0, graph.size() - 1)]
		goal_pos = random_key
	paths_possible = find_path()
	fill_map()
	if robot_pos - Vector2(0, 16) in map_grid.keys():
		robot.scale.y *= -1
	if goal_pos + Vector2(0, 16) in map_grid.keys():
		goal.scale.y *= -1
	robot.position = robot_pos
	goal.position = goal_pos
	robot.start()

func check_key(key):
	if key.y in limit_y_graph and key.x % 64 == 0:
		return false
	else:
		return true

func init_graph():
	var point_x = limit_x_graph[0]
	var point_y = limit_y_graph[0]
	while point_y <= limit_y_graph[1]:
		while point_x <= limit_x_graph[1]:
			graph[Vector2(point_x, point_y)] = 0
			point_x += 32
		point_x = limit_x_graph[0]
		point_y += 32

func fill_graph():
	var point_x = limit_x_graph[0]
	var point_y = limit_y_graph[0]
	var del_x
	var del_y
	while point_y <= limit_y_graph[1]:
		del_y = abs(goal_pos.y - point_y) / 32
		while point_x <= limit_x_graph[1]:
			del_x = abs(goal_pos.x - point_x) / 32
			graph[Vector2(point_x, point_y)] = (del_x + del_y)
			point_x += 32
		point_x = limit_x_graph[0]
		point_y += 32

func find_path():
	var min_path
	var point
	var next_point
	var dir
	var path = []
	var points_avoid = []
	var count = 0
	var directions = ["left", "right", "up", "down"]
	
	path.append(robot_pos)
	while path[path.size() - 1] != goal_pos:
		min_path = float(INF)
		next_point = null
		dir = directions[rand_gen.randi_range(0, directions.size() - 1)]
		point = path[path.size() - 1] + move_directions[dir]
		if point.x <= limit_x_graph[1] and point.x >= limit_x_graph[0] and point.y <= limit_y_graph[1] and point.y >= limit_y_graph[0] and graph.has(point) and graph[point] < min_path and point not in path and point not in points_avoid:
			min_path = graph[point]
			next_point = point
		
		if next_point == null:
			count += 1
			directions.remove_at(directions.find(dir))
			if count == 4:
				points_avoid.append(path[path.size() - 1])
				path.remove_at(path.size() - 1)
				directions = ["left", "right", "up", "down"]
				count = 0
		else:
			path.append(next_point)
			directions = ["left", "right", "up", "down"]
			count = 0
	
	return path

func init_map():
	var point_x = 0
	var point_y = 0
	var cell_x = 0
	var cell_y = 0
	while cell_y <= 18:
		while cell_x <= 17:
			point_x = cell_x * 64 + 32
			if cell_y % 2 == 1:
				point_x += 32
			point_y = (cell_y + 1) * 32
			map_grid[Vector2(point_x, point_y)] = 0
			map.set_cell(0, Vector2(cell_x, cell_y), 1, Vector2(0, 0), 0)
			if cell_x == 17 and cell_y % 2 == 1:
				map.set_cell(0, Vector2(cell_x, cell_y), 1, Vector2(3, 0), 0)
			cell_x += 1
		cell_x = 0
		cell_y += 1

func fill_map():
	var point_x = 0
	var point_y = 0
	var cell_x = 0
	var cell_y = -1
	var poss_tiles = []
	while cell_y <= 19:
		while cell_x <= 17:
			point_x = cell_x * 64 + 32
			if cell_y % 2 == 1:
				point_x += 32
			point_y = (cell_y + 1) * 32
			map_grid[Vector2(point_x, point_y)] = 0
			poss_tiles = possible_tiles(Vector2(point_x, point_y))
			map.set_cell(0, Vector2(cell_x, cell_y), 1, poss_tiles[rand_gen.randi_range(0, poss_tiles.size() - 1)], 0)
			if cell_x == 17 and cell_y % 2 == 1:
				map.set_cell(0, Vector2(cell_x, cell_y), 1, Vector2(3, 0), 0)
			
			if cell_y == -1:
				map.set_cell(0, Vector2(cell_x, cell_y), 1, Vector2(1, 0), 0)
			if cell_y == 19:
				map.set_cell(0, Vector2(cell_x, cell_y), 1, Vector2(2, 0), 0)
			cell_x += 1
		cell_x = 0
		cell_y += 1

func possible_tiles(pos):
	var possible_tiles_arr
	var top_part = false
	var bottom_part = false
	
	if pos + Vector2(0, 16) in paths_possible or pos + Vector2(0, 16) == goal_pos or pos + Vector2(0, 16) == robot_pos:
		bottom_part = true
	if pos - Vector2(0, 16) in paths_possible or pos - Vector2(0, 16) == goal_pos or pos - Vector2(0, 16) == robot_pos:
		top_part = true
	
	if top_part and bottom_part:
		possible_tiles_arr = [Vector2(0, 0), Vector2(1, 1), Vector2(2, 1), Vector2(3, 1)]
	elif top_part and !bottom_part:
		possible_tiles_arr = [Vector2(0, 0), Vector2(2, 0), Vector2(1, 1), Vector2(2, 1), Vector2(3, 1), Vector2(1, 2)]
	elif !top_part and bottom_part:
		possible_tiles_arr = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(2, 1), Vector2(3, 1), Vector2(2, 2)]
	elif !top_part and !bottom_part:
		possible_tiles_arr = [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0), Vector2(1, 1), Vector2(2, 1), Vector2(3, 1), Vector2(1, 2), Vector2(2, 2)]
	else:
		possible_tiles_arr = [Vector2(0, 0)]
	
	return possible_tiles_arr
