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
var handling = .5
var turn = 0
var force

onready var front_cast: RayCast = $FrontCast
onready var back_cast: RayCast = $BackCast


func get_input(delta):
	# General Variables
	handling = .4 if is_drifting else .6
	
	force = Vector3()
	var forward = global_transform.basis.z.normalized()
	var direction = forward.dot(velocity)
	var speed2D = Vector2(velocity.x, velocity.z).length()

	direction = sign(direction) if abs(direction) > .001 else 1.0

	# Turning Velocity Redirection: JANK AF
	var forward2D = Vector2(forward.x, forward.z)
	var direction2D = Vector2(velocity.x, velocity.z)
	var velocity_forward_angle = abs(rad2deg(forward2D.angle_to(direction2D)))
	print(velocity_forward_angle, direction)

	direction2D = direction2D.project(forward2D) * ((1 - velocity_forward_angle / 180) if direction >= 0 else velocity_forward_angle / 180)

	velocity.x = direction2D.x
	velocity.z = direction2D.y

	# General Force Application
	if is_on_floor() or is_drifting:
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
	
	# Slowing forces
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

	# Tilting: SUPER JANK AF
	front_cast.force_raycast_update()
	back_cast.force_raycast_update()
	var p1 = front_cast.get_collision_point()
	var p2 = back_cast.get_collision_point()
	var adj = p2.y - p1.y
	var hyp = p1.distance_to(p2)
	var angle = acos(adj / hyp) - deg2rad(90)
	var is_slipping = not (front_cast.is_colliding() and back_cast.is_colliding())
	var is_slipping_fw = not front_cast.is_colliding() and back_cast.is_colliding()
	var tilt = 0.01 if is_slipping else .1
	angle = angle if not is_on_floor() else -45 if is_slipping and is_slipping_fw \
		else 45 if is_slipping and not is_slipping_fw else angle

	if is_slipping:
		force += forward * (1 if is_slipping_fw else -1) * mass * 5

	$CollisionShape.rotation.x = lerp_angle($CollisionShape.rotation.x, -angle, tilt)


func _physics_process(delta):
	get_input(delta)

	turn = lerp(turn, 0, handling)
	rotate_y(turn)

	velocity += force / mass * delta
	velocity = move_and_slide(velocity, Vector3.UP)

