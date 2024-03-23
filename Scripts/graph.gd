@tool
extends Resource
class_name graph_class

@export var map         : Dictionary
@export var nodes_array : Array[graph_node_class]

func _init():
	var limit_x_graph = [32, 1120]
	var limit_y_graph = [16, 624]
	var cur_x : int   = 32
	var cur_y : int   = 16
	var i     : int   = 0
	while cur_x <= limit_x_graph[1]:
		while cur_y <= limit_y_graph[1]:
			nodes_array.append(graph_node_class.new())
			map[Vector2(cur_x, cur_y)] = i
			i += 1
			cur_y += 32
		cur_x += 32
		cur_y = 16
