extends Node2D

@export var map   : TileMap
@export var robot : StaticBody2D
@export var goal  : Polygon2D
@export var graph : graph_class

var goal_pos = 0
var rand_gen = RandomNumberGenerator.new()

func start():
	var pos = graph.map.keys()[rand_gen.randi_range(0, graph.map.size() - 1)]
	
	while graph.nodes_array[graph.map[pos]].weight == INF:
		pos = graph.map.keys()[rand_gen.randi_range(0, graph.map.size() - 1)]
	goal.position = pos
	goal_pos = pos
	
	while pos == goal_pos or graph.nodes_array[graph.map[pos]].weight == INF:
		pos = graph.map.keys()[rand_gen.randi_range(0, graph.map.size() - 1)]
	robot.position = pos
	pass

func _input(event):
	if event.is_action_pressed("move"):
		robot.start()
	if event.is_action_pressed("reset"):
		get_tree().reload_current_scene()
