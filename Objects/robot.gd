extends StaticBody2D

@onready var ray = $RayCast2D
@onready var down = $Down
@onready var up = $Up
@onready var dir_boxes = {
	"right": $Right,
	"left": $Left,
	"down": $Down,
	"up": $Up,
	
}

@export var goal : Marker2D
@export var line : Line2D

var goal_position
var del_x
var del_y
var initial_position
var initial_scale
var vertical_perm
var horizontal_perm
var path = 0
var points_traversed = []
var points_inneffective = []
var move_directions = {
	"right": Vector2(32, 0),
	"left": Vector2(-32, 0),
	"up": Vector2(0, -32),
	"down": Vector2(0, 32)}
var ineffective_mark = preload("res://Objects/ineffective.tscn")

func _ready():
	goal_position = goal.get_global_transform().get_origin()
	initial_position = position
	initial_scale = scale
	line.add_point(position)
	points_traversed.append(position)
	points_traversed.append(position)

func _physics_process(_delta):
	if position != goal_position:
		check_shorter_route()
		calculate_direction()

func _unhandled_input(event):
	if event.is_action_pressed("move"):
		if position != goal_position:
			check_shorter_route()
			calculate_direction()

func calculate_direction():
	var dir
	vertical_perm = check_next_position("up") or check_next_position("down")
	horizontal_perm = check_next_position("left") or check_next_position("right")
	del_x = goal_position.x - position.x
	del_y = goal_position.y - position.y
	
	if abs(del_x) >= abs(del_y) and del_x != 0:
		if horizontal_perm:
			dir = move_horizontal(false)
		elif vertical_perm:
			dir = move_vertical(false)
		else:
			clear_points_ineffective()
	elif abs(del_y) > abs(del_x) and del_y != 0:
		if vertical_perm:
			dir = move_vertical(false)
		elif horizontal_perm:
			dir = move_horizontal(false)
		else:
			clear_points_ineffective()
	
	if lenght_of_path_in_direction()[1] > 1:
		var max_dir = lenght_of_path_in_direction()[0]
		if max_dir != dir or dir == null:
			if (dir == "right" and del_x < 0) or (dir == "left" and del_x > 0) or (dir == "up" and del_y > 0) or (dir == "down" and del_y < 0):
				dir = lenght_of_path_in_direction()[0]
			if (del_x < 0 and max_dir == "left") or (del_x > 0 and max_dir == "right") or (del_y < 0 and max_dir == "up") or (del_y > 0 and max_dir == "down"):
				dir = lenght_of_path_in_direction()[0]
	
	if dir != null:
		move(dir)
	else:
		step_back()

func move_horizontal(repeat):
	if del_x > 0:
		if check_next_position("right"):
			return "right"
		else:
			if vertical_perm and !repeat:
				return move_vertical(true)
			else:
				return "left"
	else:
		if check_next_position("left"):
			return "left"
		else:
			if vertical_perm and !repeat:
				return move_vertical(true)
			else:
				return "right"

func move_vertical(repeat):
	if del_y < 0:
		if check_next_position("up"):
			return "up"
		else:
			if horizontal_perm and !repeat:
				return move_horizontal(true)
			else:
				return "down"
	else:
		if check_next_position("down"):
			return "down"
		else:
			if horizontal_perm and !repeat:
				return move_horizontal(true)
			else:
				return "up"

func mark_point_ineffective(pos):
	if pos not in points_traversed or pos == position:
		var mark = ineffective_mark.instantiate()
		mark.position = pos
		$"../Marks".add_child(mark)
		points_inneffective.append(pos)

func clear_points_ineffective():
	for dir in move_directions.keys():
		points_inneffective.erase(position + move_directions[dir])
	for i in $"../Marks".get_children():
		i.queue_free()
	for i in points_inneffective:
		if i not in points_traversed or i == position:
			var mark = ineffective_mark.instantiate()
			mark.position = i
			$"../Marks".add_child(mark)

func step_back():
	mark_point_ineffective(position)
	mark_point_ineffective(points_traversed[points_traversed.size() - 1])
	line.remove_point(len(line.points)-1)
	scale.y *= -1
	position = points_traversed[points_traversed.size() - 2]
	points_traversed.remove_at(points_traversed.size() - 1)
	path -= 1

func check_next_position(dir):
	ray.target_position = move_directions[dir]
	ray.target_position.y *= scale.y
	ray.force_raycast_update()
	if (position + move_directions[dir]) not in points_traversed and (position + move_directions[dir]) not in points_inneffective and (!ray.is_colliding() or ((dir == "down" and ((scale.y == 1 and !down.has_overlapping_bodies()) or (scale.y == -1 and !up.has_overlapping_bodies()))) or (dir == "up" and ((scale.y == -1 and !down.has_overlapping_bodies()) or (scale.y == 1 and !up.has_overlapping_bodies()))))):
		return true
	else:
		mark_point_ineffective(position + move_directions[dir])
		return false

func lenght_of_path_in_direction():
	var can_pass = true
	var value = 0
	var direction
	var max_val = 0
	for dir in move_directions.keys():
		value = 0
		can_pass = true
		ray.target_position = move_directions[dir]
		ray.target_position.y *= scale.y
		ray.force_raycast_update()
		while can_pass:
			if value != 0:
				ray.target_position += move_directions[dir]
			ray.force_raycast_update()
			if (position + move_directions[dir]) not in points_traversed and (position + move_directions[dir]) not in points_inneffective and !ray.is_colliding():
				can_pass = true
				value += 1
			else:
				can_pass = false
		
		if value > max_val:
			max_val = value
			direction = dir
	
	return [direction, max_val]

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
	
	for i in points_traversed:
		if position.y == i.y:
			pass

func move_to_shorter_route(pos):
	var temp_arr
	var point_id
	points_traversed.remove_at(points_traversed.size() - 1)
	point_id = points_traversed.find(pos, 0)
	if point_id == -1:
		point_id = points_traversed.size() - 1
	temp_arr = points_traversed.slice(point_id + 1)
	points_traversed = points_traversed.slice(0, point_id + 1)
	line.points = points_traversed
	position = pos
	if temp_arr.size() % 2 == 0:
		scale.y *= -1
	print(temp_arr)
	for i in temp_arr.slice(1):
		mark_point_ineffective(i)

func move(dir):
	scale.y *= -1
	position += move_directions[dir]
	path += 1
	points_traversed.append(position)
	line.add_point(position)
