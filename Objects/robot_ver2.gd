extends StaticBody2D

@onready var ray = $RayCast2D
@onready var down = $Down
@onready var up = $Up
@onready var right = $Right
@onready var left = $Left
@onready var dir_boxes = {
	"right": right,
	"left": left,
	"down": down,
	"up": up
}

@export var goal : Marker2D
@export var line : Line2D
@export var line_path : Line2D

var goal_pos
var del_x
var del_y
var initial_pos
var initial_scale
var limit_x = [32, 1120]
var limit_y = [16, 624]
var limit_x_traversed = [1900, 0]
var limit_y_traversed = [1900, 0]
var path = []
var points_traversed = []
var points_avoid = []
var possible_dir = []
var graph = {}
var move_directions = {
	"right": Vector2(32, 0),
	"left": Vector2(-32, 0),
	"up": Vector2(0, -32),
	"down": Vector2(0, 32)}
var value_label = preload("res://Objects/value.tscn")

func _ready():
	set_physics_process(false)

func start():
	initial_pos = position
	initial_scale = scale
	goal_pos = goal.get_global_transform().get_origin()
	line.add_point(position)
	points_traversed.append(position)
	init_graph()
	scan_for_obstacles()
	update_tiles()
	set_physics_process(true)

func _physics_process(_delta):
	if position != goal_pos:
		if scan_for_obstacles() or path == []:
			update_tiles()
			path = []
			compute_shortest_path()
		
		if path != []:
			move()
	else:
		normalize_grid()
		update_tiles()
		set_physics_process(false)

func compute_shortest_path():
	var min_path = float(INF)
	var next_point
	var point
	path = []
	for i in possible_dir:
		if graph[i] < min_path:
			min_path = graph[i]
			next_point = i
	
	if min_path == float(INF) or next_point == null or next_point in points_traversed:
		points_avoid.append(position)
		clear_path()
	else:
		path.append(next_point)
		var prev_point
		
		while path[path.size() - 1] != goal_pos:
			min_path = float(INF)
			prev_point = next_point
			for dir in move_directions.keys():
				point = path[path.size() - 1] + move_directions[dir]
				if graph.has(point) and graph[point] != float(INF) and graph[point] < min_path and point not in path and point not in points_traversed and point not in points_avoid:
					min_path = graph[point]
					next_point = point
			
			
			if min_path == float(INF) or prev_point == next_point:
				points_avoid.append(next_point)
				path = [path[0]]
				if possible_dir.size() > 1:
					possible_dir.erase(path[0])
					path = [possible_dir[0]]
				else:
					if position != initial_pos:
						position = points_traversed[points_traversed.size() - 1]
						points_traversed.remove_at(points_traversed.size() - 1)
						path = [position]
			else:
				path.append(next_point)

func move():
	scale.y *= -1
	position = path[0]
	line_path.points = path
	path.remove_at(0)
	points_traversed.append(position)
	line.points = points_traversed
	if position.x > limit_x_traversed[1]:
		limit_x_traversed[1] = position.x
	if position.x < limit_x_traversed[0]:
		limit_x_traversed[0] = position.x
	
	if position.y > limit_y_traversed[1]:
		limit_y_traversed[1] = position.y
	if position.y < limit_y_traversed[0]:
		limit_y_traversed[0] = position.y

func clear_path():
	path = []
	points_traversed = []
	points_traversed.append(initial_pos)
	position = initial_pos
	scale = initial_scale
	line.clear_points()
	line.add_point(position)

func init_graph():
	var point_x = limit_x[0]
	var point_y = limit_y[0]
	while point_y <= limit_y[1]:
		del_y = abs(goal_pos.y - point_y) / 32
		while point_x <= limit_x[1]:
			del_x = abs(goal_pos.x - point_x) / 32
			graph[Vector2(point_x, point_y)] = (del_x + del_y)
			mark_tiles(Vector2(point_x, point_y))
			point_x += 32
		point_x = limit_x[0]
		point_y += 32

func mark_tiles(pos):
	var point_value = value_label.instantiate()
	point_value.position = pos
	point_value.text = str(graph[pos])
	$"../TileValues".add_child(point_value)

func update_tiles():
	for i in $"../TileValues".get_children():
		i.queue_free()
	for i in graph.keys():
		mark_tiles(i)

func scan_for_obstacles():
	var next_pos
	var updated = false
	possible_dir = []
	for dir in move_directions.keys():
		var scale_dir = dir
		next_pos = position + move_directions[dir]
		if dir == "down" and scale.y == -1:
			scale_dir = "up"
		if dir == "up" and scale.y == -1:
			scale_dir = "down"
		
		if dir_boxes[scale_dir].has_overlapping_bodies() and graph.has(next_pos) and graph[next_pos] != float(INF):
			graph[next_pos] = float(INF)
			updated = true
		elif next_pos not in points_traversed and next_pos not in points_avoid and graph.has(next_pos) and !dir_boxes[scale_dir].has_overlapping_bodies():
			possible_dir.append(position + move_directions[dir])
	
	if possible_dir.size() != 0:
		if scan_possible_dir():
			updated = true
	
	return updated

func scan_possible_dir():
	var no_min = true
	var temp_arr = []
	var point
	var updated = false
	for i in possible_dir:
		temp_arr.append(graph[i])
		if graph[position] > graph[i]:
			no_min = false
	
	point = possible_dir[temp_arr.find(temp_arr.min())]
	
	if !no_min and graph[position] - graph[point] != 1:
		if position.x - point.x != 0:
			if position.x - point.x < 0:
				change_value_triangle_reverse(point, "right")
			else:
				change_value_triangle_reverse(point, "left")
		elif position.y - point.y != 0:
			if position.y - point.y < 0:
				change_value_triangle_reverse(point, "down")
			else:
				change_value_triangle_reverse(point, "up")
		updated = true
	
	if no_min:
		if position.x - point.x != 0:
			if goal_pos.y - position.y > 0:
				change_value_triangle(point, "up")
			else:
				change_value_triangle(point, "down")
		elif position.y - point.y != 0:
			if goal_pos.x - position.x > 0:
				change_value_triangle(point, "left")
			else:
				change_value_triangle(point, "right")
		updated = true
	
	return updated

func change_value_triangle(point, direction):
	var diff = graph[point] + 1 - graph[position]
	var reverse = false
	if graph[point] < graph[position]:
		reverse = true
		diff *= -1
	
	if direction == "left" or direction == "right":
		var point_x
		if direction == "left":
			point_x = limit_x_traversed[1]
		if direction == "right":
			point_x = limit_x_traversed[0]
		while point_x >= limit_x[0] and point_x <= limit_x[1]:
			var point_y = limit_y[0]
			while point_y >= limit_y[0] and point_y <= limit_y[1]:
				if Vector2(point_x, point_y) != point or reverse:
					graph[Vector2(point_x, point_y)] += diff
				point_y += 32
			if direction == "left":
				point_x -= 32
			elif direction == "right":
				point_x += 32
	elif direction == "down" or direction == "up":
		var point_y
		if direction == "down":
			point_y = limit_y_traversed[0]
		if direction == "up":
			point_y = limit_y_traversed[1]
		while point_y >= limit_y[0] and point_y <= limit_y[1]:
			var point_x = limit_x[0]
			while point_x >= limit_x[0] and point_x <= limit_x[1]:
				if Vector2(point_x, point_y) != point or reverse:
					graph[Vector2(point_x, point_y)] += diff
				point_x += 32
			if direction == "up":
				point_y -= 32
			elif direction == "down":
				point_y += 32

func change_value_triangle_reverse(point, direction):
	var diff = graph[position] - 1 - graph[point]
	
	if direction == "left" or direction == "right":
		var point_x = point.x
		while point_x >= limit_x[0] and point_x <= limit_x[1]:
			var point_y = limit_y[0]
			while point_y >= limit_y[0] and point_y <= limit_y[1]:
				graph[Vector2(point_x, point_y)] += diff
				point_y += 32
			if direction == "left":
				point_x -= 32
			elif direction == "right":
				point_x += 32
	elif direction == "down" or direction == "up":
		var point_y = point.y
		while point_y >= limit_y[0] and point_y <= limit_y[1]:
			var point_x = limit_x[0]
			while point_x >= limit_x[0] and point_x <= limit_x[1]:
				graph[Vector2(point_x, point_y)] += diff
				point_x += 32
			if direction == "up":
				point_y -= 32
			elif direction == "down":
				point_y += 32

func normalize_grid():
	var diff = graph[goal_pos]
	var point_x = limit_x[0]
	while point_x >= limit_x[0] and point_x <= limit_x[1]:
		var point_y = limit_y[0]
		while point_y >= limit_y[0] and point_y <= limit_y[1]:
			graph[Vector2(point_x, point_y)] -= diff
			point_y += 32
		point_x += 32
