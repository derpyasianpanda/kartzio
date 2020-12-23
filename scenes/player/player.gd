extends KinematicBody

const GRAVITY = Vector3.DOWN * 10
const ACCEL = 10
const DECEL = -8
const FRICTION = 0.6
const DRAG = 0.001
const TURN_RATE = 1

export var mass = 1500
var is_drifting = false
var velocity = Vector3()
var handling = .65
var turn = 0
var force

onready var front_cast: RayCast = $"FrontCast"
onready var back_cast: RayCast = $"BackCast"

func get_input(delta):
	handling = .5 if is_drifting else .6
	
	force = Vector3()
	var forward = global_transform.basis.z.normalized()
	var direction = forward.dot(velocity)
	var speed2D = Vector2(velocity.x, velocity.z).length()

	direction = max(.4, abs(direction)) if abs(direction) <= 1 \
		else sign(direction)

	if Input.is_action_pressed("right"):
		turn += direction * -TURN_RATE * delta
	if Input.is_action_pressed("left"):
		turn += direction * TURN_RATE * delta

	if Input.is_action_pressed("forward"):
		force += ACCEL * forward * mass
	if Input.is_action_pressed("backward"):
		force += DECEL * forward * mass

	if Input.is_action_just_pressed("jump"):
		is_drifting = true
		if is_on_floor():
			force += Vector3.UP * mass * 150
	
	if Input.is_action_just_released("jump"):
		is_drifting = false
	
	var friction = \
		FRICTION * 10 * mass * -velocity.normalized()
	friction.y = 0
	var drag = DRAG * -velocity * speed2D
	if speed2D > .05:
		force += friction
		force += drag
	else:
		velocity = Vector3()

	force += GRAVITY * mass


func _physics_process(delta):
	get_input(delta)

	turn = lerp(turn, 0, handling)
	rotate_y(turn)

	velocity += force / mass * delta
	velocity = move_and_slide(velocity, Vector3.UP)

	# JANK AF
	front_cast.force_raycast_update()
	back_cast.force_raycast_update()
	var p1 = front_cast.get_collision_point()
	var p2 = back_cast.get_collision_point()
	var adj = p2.y - p1.y
	var hyp = p1.distance_to(p2)
	var angle = deg2rad(round(rad2deg(acos(adj / hyp) - deg2rad(90))))
	var tilt = 0.1 if front_cast.is_colliding() and back_cast.is_colliding() else .01
	$CollisionShape.rotation.x = lerp_angle($CollisionShape.rotation.x, -angle, tilt)



