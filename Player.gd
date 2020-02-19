extends KinematicBody

# this is how fast we'll move horizontally in units per seconds
export var move_speed = 5.0

# this is how fast we will raise up if we're going up stairs in units per seconds
export var move_up_speed = 10.0

# We need to know our characters size
# Our character size is 2 * its radius (2 * 0.3) + its height (1.0)
export var character_height = 1.6

# when we are falling we will fall faster and faster
var fall_velocity = 0.0

# Called every physics frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	# first react to keyboard input
	_move_character(delta)
	
	# now adjust how high we are
	_handle_height(delta)

func _move_character(delta):
	# We're purely using our physics engine to detect when our player runs into walls
	# this is why our collision shape is a ring around the middle of the body. 
	
	# In Project -> Project Settings you will find the input mapping where these inputs are defined
	
	# Define in which direction we are moving
	var move_direction = Vector3(0.0, 0.0, 0.0)
	
	# if our left button is pressed we want to go left
	if Input.is_action_pressed("ui_left"):
		move_direction.x -= move_speed
	
	# if our right button is pressed we want to go right
	if Input.is_action_pressed("ui_right"):
		move_direction.x += move_speed
	
	# if our up button is pressed we want to go up
	if Input.is_action_pressed("ui_up"):
		move_direction.z -= move_speed
		
	# if our down button is pressed we want to go down
	if Input.is_action_pressed("ui_down"):
		move_direction.z += move_speed
	
	if move_direction.length() > 0:
		# See how far we'll move in our timeframe
		var move_distance = move_direction * delta
		
		# Now we use move and collide to actually move, it will move our distance unless we hit something
		move_and_collide(move_distance)
		
		# Finally make our player face the way we're moving.
		# We're changing the gimble node so our kinematic body keeps oriented the way it is.
		var lookat_point = $Gimble.global_transform.origin + move_distance
		$Gimble.look_at(lookat_point, Vector3.UP)

func _get_ground_position():
	var ground_position = null
	
	# Check all 4 raycasts, each on a corner of our character
	for raycast in $RayCasts.get_children():
		# Check if this raycast is colliding, if it is we've found the ground beneath our feet
		if raycast.is_colliding():
			# get our collision point and take the y to get our height
			var position = raycast.get_collision_point().y
			if ground_position == null:
				# this is the first we found, use it
				ground_position = position
			elif ground_position < position:
				# our new position is higher, use it
				ground_position = position
	
	return ground_position

func _handle_height(delta):
	# As we've centered our character we want half its height
	var character_half_height =  character_height / 2.0
	
	# check how high above the ground we are
	var ground_position = _get_ground_position()
	
	# we are not anywhere above the ground? exit
	if ground_position == null:
		return
	
	# we get our position from our global transform
	var our_position = global_transform.origin
	
	# now find out how high up our feet are by taking the y from our position and subtracting half our characters height
	var feet_position = our_position.y - character_half_height
	
	# now subtract the ground position to find out how high above the ground we are
	var distance_to_the_ground = feet_position - ground_position
	
	# by how much do we want to move?
	var move_distance = 0.0
	
	if distance_to_the_ground <= 0.0:
		# We are either on the ground or too low because we are going up stairs
		# Calculate how much we will move our character up:
		move_distance = move_up_speed * delta
		
		# but don't move up too far
		if move_distance > -distance_to_the_ground:
			move_distance = -distance_to_the_ground
		
		# we are (no longer) falling so make sure this is zero
		fall_velocity = 0.0
	else:
		# we are not colliding so we must be falling, increase our fall velocity
		fall_velocity += 9.8 * delta
		
		# now use our velocity to calculate how far we will far
		move_distance = fall_velocity * delta
		
		# if we'll fall through the ground, stop at the ground
		if move_distance > distance_to_the_ground:
			move_distance = distance_to_the_ground
		
		# we are falling so make it negative
		move_distance = -move_distance
		
	# now we use move and collide again to fall
	move_and_collide(Vector3(0.0, move_distance, 0.0))
