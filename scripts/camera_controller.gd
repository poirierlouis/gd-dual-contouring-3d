class_name CameraController

extends Camera3D

# How fast the agent moves in m/s.
@export var speed := 50.0

@export var sprint_speed := 200.0

# How fast the agent orientes towards the mouse.
@export var mouse_sensibility := 4.0

# Triggers when agent moved (every 10 ticks).
signal agent_moved(position: Vector3)

# Current velocity of agent.
var velocity := Vector3.ZERO

var _rate := 0
var _previousPosition := Vector3.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	agent_moved.emit(self.position)

func _input(event):
	if event is InputEventMouseMotion:
		look_agent(event.relative * 0.001 * mouse_sensibility)

func _physics_process(delta):
	_rate += 1
	move_agent(delta)
	if _rate == 10:
		_rate = 0

# Orientate agent's camera towards the center of the viewport, moving
# in relative coordinates using mouse's movements.
func look_agent(mouse):
	self.rotation.x -= mouse.y
	self.rotation.y -= mouse.x

# Move agent on inputs.
#
# Emits [agent_moved] with position changed, every 10 ticks.
func move_agent(delta):
	var current_speed := speed
	var direction = Vector3.ZERO
	
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_backward"):
		direction.z += 1
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1
	if Input.is_action_pressed("move_up"):
		direction.y += 1
	if Input.is_action_pressed("move_down"):
		direction.y -= 1
	if Input.is_action_pressed("sprint"):
		current_speed += sprint_speed
	
	if direction == Vector3.ZERO:
		return
	direction = direction.normalized()
	velocity.x = direction.x * current_speed * delta
	velocity.y = direction.y * current_speed * delta
	velocity.z = direction.z * current_speed * delta
	self.translate(velocity)
	if _rate == 10:
		agent_moved.emit(self.position)
		_previousPosition = self.position
		_rate = 0
