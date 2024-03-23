extends StaticBody2D

@export var main      : Node2D
@export var goal      : Marker2D
@export var line      : Line2D

var value_label = preload("res://Objects/value.tscn")

var goal_pos          : Vector2
var start_pos         : Vector2
var last_pos          : Vector2
var k_m   = 0
var k_old = 0
var U = []
var move_directions = {
	"right" : Vector2(32, 0),
	"left"  : Vector2(-32, 0),
	"up"    : Vector2(0, -32),
	"down"  : Vector2(0, 32)}

func _ready():
	set_physics_process(false)
	pass

func start():
	start_pos = position
	last_pos = start_pos
	goal_pos = goal.global_position
	main.graph.nodes_array[main.graph.map[goal_pos]].rhs = 0
	U.append({goal_pos: calculate_key(goal_pos)})
	
	line.add_point(position)
	update_tiles()
	compute_shortest_path()
	set_physics_process(true)
	pass

func _physics_process(_delta):
	if start_pos != goal_pos:
		var pos_new = next_in_shortest_path()
		print("TURN ", pos_new)
		if pos_new == null:
			pos_new = start_pos
		k_m += heuristic_s(start_pos, pos_new)
		start_pos = pos_new
		move_to(start_pos)
		compute_shortest_path()
	pass

func compute_shortest_path():
	while check_less(top_key(), calculate_key(start_pos)) or main.graph.nodes_array[main.graph.map[start_pos]].rhs != main.graph.nodes_array[main.graph.map[start_pos]].g:
		k_old = top_key()
		var u_point = U_pop()
		if check_less(k_old, calculate_key(u_point)):
			U.append({u_point: calculate_key(u_point)})
		elif main.graph.nodes_array[main.graph.map[u_point]].rhs < main.graph.nodes_array[main.graph.map[u_point]].g:
			main.graph.nodes_array[main.graph.map[u_point]].g = main.graph.nodes_array[main.graph.map[u_point]].rhs
			for i in move_directions.values():
				update_vertex(u_point + i)
		else:
			main.graph.nodes_array[main.graph.map[u_point]].g = INF
			update_vertex(u_point)
			for i in move_directions.values():
				update_vertex(u_point + i)
	pass

func top_key():
	if U.size() > 0:
		U.sort_custom(sort_by_values)
		return U[0].values()[0]
	else:
		return [INF, INF]
	pass

func U_pop():
	return U.pop_at(0).keys()[0]

func calculate_key(pos : Vector2):
	var g = main.graph.nodes_array[main.graph.map[pos]].g
	var rhs = main.graph.nodes_array[main.graph.map[pos]].rhs
	return [min(g, rhs) + heuristic_s(pos, goal_pos) + k_m, min(g,rhs)]
	pass

func heuristic_s(pos_1 : Vector2, pos_2 : Vector2):
	var x_distance   = abs(pos_1.x - pos_2.x) + main.graph.nodes_array[main.graph.map[pos_1]].weight
	var y_distance   = abs(pos_1.y - pos_2.y) + main.graph.nodes_array[main.graph.map[pos_1]].weight
	return max(x_distance, y_distance)
	pass

func next_in_shortest_path():
	var min_rhs = INF
	var pos_next
	for i in move_directions.values():
		if main.graph.map.has(position + i) and main.graph.nodes_array[main.graph.map[position + i]].rhs < min_rhs:
			min_rhs = main.graph.nodes_array[main.graph.map[position + i]].rhs + main.graph.nodes_array[main.graph.map[position + i]].weight
			pos_next = start_pos + i
	if pos_next:
		return pos_next
	else:
		return null
	pass

func update_vertex(pos : Vector2):
	if !main.graph.map.has(pos):
		return
	
	if pos != goal_pos:
		var min_rhs = INF
		for i in move_directions.values():
			if main.graph.map.has(pos + i):
				min_rhs = min(min_rhs, main.graph.nodes_array[main.graph.map[pos + i]].g + heuristic_s(pos, pos + i))
			main.graph.nodes_array[main.graph.map[pos]].rhs = min_rhs
	var id_in_U
	for i in range(len(U)):
		if U[i].keys()[0] == pos:
			id_in_U = i
	if id_in_U:
		U.pop_at(id_in_U)
	if main.graph.nodes_array[main.graph.map[pos]].rhs != main.graph.nodes_array[main.graph.map[pos]].g:
		U.append({pos: calculate_key(pos)})
	pass

func move_to(pos : Vector2):
	position = pos
	line.add_point(position)
	pass

func sort_by_values(a : Dictionary, b : Dictionary):
	if a.values()[0][0] < b.values()[0][0]:
		return true
	return false
	pass

func check_less(arr1 : Array, arr2 : Array):
	return arr1[0] < arr2[0] or (arr1[0] == arr2[0] and arr1[1] < arr2[1])
	pass

func mark_tiles(pos):
	var point_value = value_label.instantiate()
	point_value.position = pos
	point_value.text = str(main.graph.nodes_array[main.graph.map[pos]].weight)
	$"../TileValues".add_child(point_value)

func update_tiles():
	for i in $"../TileValues".get_children():
		i.queue_free()
	for i in main.graph.map.keys():
		mark_tiles(i)
