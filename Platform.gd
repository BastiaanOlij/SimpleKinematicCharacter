extends StaticBody

# Small note here, the area collision shape is larger than I'd like because of the way we've implemented our kinematic character
# It's collision shape starts fairly high.
# If you implement your own kinematic character with a capsule collision shape you could keep the detection area pretty thin.
# Also for now we're only checking kinematic characters. 
# If we want rigid bodies places onto the platform to move as well I guess the same technique could be used. 

export (NodePath) var move_to = null
export var acceleration = 10.0
export var slowdown_factor = 0.5

onready var start_position = global_transform.origin
onready var end_position = global_transform.origin

enum {
	TARGET_START,
	TARGET_END
}

var velocity = Vector3(0.0, 0.0, 0.0)
var target_pos = Vector3(0.0, 0.0, 0.0)
var start_or_end = TARGET_END

# Called when the node enters the scene tree for the first time.
func _ready():
	if move_to:
		var target = get_node(move_to)
		if target:
			end_position = target.global_transform.origin
	
	target_pos = end_position

func _physics_process(delta):
	if start_position == end_position:
		return
	
	var current_pos = global_transform.origin
	var distance_to_target = target_pos - current_pos
	if distance_to_target.length() < 0.1:
		# nearly there, lets turn around
		if start_or_end == TARGET_END:
			start_or_end = TARGET_START
			target_pos = start_position
		else:
			start_or_end = TARGET_END
			target_pos = end_position
		
		distance_to_target = target_pos - current_pos
	
	if distance_to_target.length() < velocity.length() * slowdown_factor:
		# if after a second we'd overshoot our target, lets decelarate
		velocity *= clamp(1.0 - (delta * acceleration), 0.0, 1.0)
	else:
		# lets accelerate towards our target
		velocity += distance_to_target.normalized() * delta * acceleration
	
	# Who are on the platform?
	var on_platform = $DetectOnPlatform.get_overlapping_bodies()
	
	# How much are we moving?
	var move = velocity * delta
	
	# Should detect if something is in the way here... 
	
	# Move our platform
	global_transform.origin += move
	
	# Also move anything on our platform
	for body in on_platform:
		if body == self:
			# don't move ourselves, we've already moved...
			pass
		elif body is KinematicBody:
				body.global_transform.origin += move
