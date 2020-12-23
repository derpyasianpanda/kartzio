extends Camera

var vel = Vector3()
var speed = 3
onready var car = $"../Player"

func _process(delta):
	var car_pos = car.global_transform.origin
	var car_dir = car.global_transform.basis.z
	var new_pos = car_pos - (car_dir * 3.5)

	var cam_pos = global_transform.origin
	cam_pos.y -= 1.75
	vel += -(cam_pos - new_pos) * delta * speed
	look_at_from_position(vel, car_pos, Vector3(0,1,0))

