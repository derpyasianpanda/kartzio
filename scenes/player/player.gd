extends KinematicBody

const GRAVITY = Vector3.DOWN * 10
const ACCEL = 10
const DECEL = -8
const FRICTION = 0.6
const DRAG = 0.00001
const TURN_RATE = 1

export var mass = 1000
var velocity = Vector3()
var handling = .45
var turn = 0
var force


func get_input(delta):
	force = Vector3()
	var forward = global_transform.basis.z.normalized()
	var direction = forward.dot(velocity)
	var speed2D = Vector2(velocity.x, velocity.z).length()

	direction = 0 if abs(direction) <= .05 \
		else sign(direction)

	if speed2D > .05:
		if Input.is_action_pressed("right"):
			turn += direction * -TURN_RATE * delta
		if Input.is_action_pressed("left"):
			turn += direction * TURN_RATE * delta

	if Input.is_action_pressed("forward"):
		force += ACCEL * forward * mass
	if Input.is_action_pressed("backward"):
		force += DECEL * forward * mass
	
	var friction = \
		FRICTION * 10 * mass * -velocity.normalized()
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

