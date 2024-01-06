extends StaticBody2D

@onready var ray = $RayCast2D
@onready var down = $Down
@onready var up = $Up

var inputs = {"right": Vector2(32, 0),
			"left": Vector2(-32, 0),
			"up": Vector2(0, -32),
			"down": Vector2(0, 32)}

func _unhandled_input(event):
	for dir in inputs.keys():
		if event.is_action_pressed(dir):
			move(dir)

func move(dir):
	ray.target_position = inputs[dir]
	ray.target_position.y *= scale.y
	ray.force_raycast_update()
	if !ray.is_colliding() or ((dir == "down" and ((scale.y == 1 and !down.has_overlapping_bodies()) or (scale.y == -1 and !up.has_overlapping_bodies()))) or (dir == "up" and ((scale.y == -1 and !down.has_overlapping_bodies()) or (scale.y == 1 and !up.has_overlapping_bodies())))):
		scale.y *= -1
		position += inputs[dir]
