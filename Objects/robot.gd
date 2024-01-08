extends StaticBody2D

@onready var ray = $RayCast2D
@onready var down = $Down
@onready var up = $Up

@export var goal : Marker2D
@export var line : Line2D

var goal_position
var del_x
var del_y
var initial_position
var initial_scale
var path = 0
var points_traversed = []
var points_inneffective = []
var move_directions = {
	"right": Vector2(32, 0),
	"left": Vector2(-32, 0),
	"up": Vector2(0, -32),
	"down": Vector2(0, 32)}

func _ready():
	goal_position = goal.get_global_transform().get_origin()
	initial_position = position
	initial_scale = scale
	line.add_point(position)
	points_traversed.append(position)
	points_traversed.append(position)

func _physics_process(delta):
	if position != goal_position:
		check_shorter_route()
		calculate_direction()

func calculate_direction():
	var dir
	del_x = goal_position.x - position.x
	del_y = goal_position.y - position.y
	if abs(del_x) >= abs(del_y) and del_x != 0 and (check_next_position("left") or check_next_position("right")):
		if del_x > 0 and check_next_position("right"):
			dir = "right"
		else:
			dir = "left"
	if dir == null and del_y != 0 and (check_next_position("up") or check_next_position("down")):
		if del_y > 0 and check_next_position("down"):
			dir = "down"
		else:
			dir = "up"
	
	if dir != null:
		move(dir)
	else:
		step_back()

func step_back():
	points_traversed.remove_at(len(points_traversed) - 1)
	points_inneffective.append(position)
	points_inneffective.append(points_traversed[points_traversed.size() - 1])
	line.remove_point(len(line.points)-1)
	scale.y *= -1
	position = points_traversed[points_traversed.size() - 1]
	path -= 1

func check_next_position(dir):
	ray.target_position = move_directions[dir]
	ray.target_position.y *= scale.y
	ray.force_raycast_update()
	if (position + move_directions[dir]) not in points_traversed and (position + move_directions[dir]) not in points_inneffective and (!ray.is_colliding() or ((dir == "down" and ((scale.y == 1 and !down.has_overlapping_bodies()) or (scale.y == -1 and !up.has_overlapping_bodies()))) or (dir == "up" and ((scale.y == -1 and !down.has_overlapping_bodies()) or (scale.y == 1 and !up.has_overlapping_bodies()))))):
		return true
	else:
		return false

func check_possible_position(dir):
	ray.target_position = move_directions[dir]
	ray.target_position.y *= scale.y
	ray.force_raycast_update()
	if position + move_directions[dir] != points_traversed[points_traversed.size() - 2] and (!ray.is_colliding() or ((dir == "down" and ((scale.y == 1 and !down.has_overlapping_bodies()) or (scale.y == -1 and !up.has_overlapping_bodies()))) or (dir == "up" and ((scale.y == -1 and !down.has_overlapping_bodies()) or (scale.y == 1 and !up.has_overlapping_bodies()))))):
		return true
	else:
		return false

func check_shorter_route():
	for dir in move_directions.keys():
		if check_possible_position(dir) and position + move_directions[dir] in points_traversed:
			move_to_shorter_route(position + move_directions[dir])
	
func move_to_shorter_route(pos):
	points_traversed.remove_at(points_traversed.size() - 1)
	var point_id = points_traversed.find(pos, 0)
	var temp_arr = points_traversed.slice(point_id + 1)
	points_inneffective.append_array(temp_arr)
	position = pos
	if temp_arr.size() % 2 == 0:
		scale.y *= -1
	points_traversed = points_traversed.slice(0, point_id + 1)
	line.points = points_traversed

func move(dir):
	scale.y *= -1
	position += move_directions[dir]
	path += 1
	points_traversed.append(position)
	line.add_point(position)

func clear():
	position = initial_position
	scale = initial_scale
	path = 0
	line.clear_points()
	line.add_point(position)
