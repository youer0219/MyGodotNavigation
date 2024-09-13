extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -500.0
const SmallJumpVelocity := -470.0
const TinyJumpVelocity := -370.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var _pathFind2D:TileMapPathFind
@export var _player:CharacterBody2D
var _path :TileMapPathFind.Stack = TileMapPathFind.Stack.new()
var _target:TileMapPathFind.PointInfo = null
var _prevTarget:TileMapPathFind.PointInfo = null
var JumpDistanceHeightThreshold:float = 120.0
@onready var path_find_timer = $PathFindTimer


func GoToNextPointInPath():
	if _path && _path.count <= 0:
		_prevTarget = null
		_target = null
		return
	
	_prevTarget = _target
	_target = _path.pop()

func DoPathFinding():
	_path = _pathFind2D.GetPlaform2DPath(self.position,_player.position)
	GoToNextPointInPath()



func _physics_process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		path_find_timer.start()
	
	var new_velocity = velocity
	var direction:Vector2 = Vector2.ZERO
	# Add the gravity.
	if not is_on_floor():
		new_velocity.y += gravity * delta

	# Handle jump.
	if _target != null:
		if _target.Position.x - 5 > position.x:
			direction.x = 1
		elif _target.Position.x +5 < position.x:
			direction.x = -1
		else:
			if is_on_floor():
				GoToNextPointInPath()
				new_velocity = Jump(new_velocity)
	
	if direction:
		new_velocity.x = direction.x * SPEED
	else:
		new_velocity.x = move_toward(new_velocity.x, 0, SPEED)
	
	velocity  = new_velocity
	#print(velocity)
	move_and_slide()

func JumpRightEdgeToLeftEdge()->bool:
	if _prevTarget.isRightEdge && _target.isLeftEdge && _prevTarget.Position.y <= _target.Position.y && _prevTarget.Position.x < _target.Position.x:
		return true
	return false 

func JumpleftEdgeToRightEdge()->bool:
	if _prevTarget.isLeftEdge && _target.isRightEdge && _prevTarget.Position.y <= _target.Position.y && _prevTarget.Position.x > _target.Position.x:
		return true
	return false 

func Jump(new_velocity:Vector2)->Vector2:
	if _prevTarget == null || _target == null || _target.isPositionPoint:
		return new_velocity
	
	if _prevTarget.Position.y < _target.Position.y && _prevTarget.Position.distance_to(_target.Position) < JumpDistanceHeightThreshold:
		return new_velocity
	
	if _prevTarget.Position.y < _target.Position.y && _target.isFallTile:
		return new_velocity
	
	if _prevTarget.Position.y > _target.Position.y ||  JumpleftEdgeToRightEdge() || JumpRightEdgeToLeftEdge():
		var heightDistance:int = _pathFind2D.local_to_map(_target.Position).y - _pathFind2D.local_to_map(_prevTarget.Position).y
		if abs(heightDistance) <= 1:
			new_velocity.y = TinyJumpVelocity
		elif abs(heightDistance) == 2:
			new_velocity.y = SmallJumpVelocity
		else:
			new_velocity.y = JUMP_VELOCITY
	
	return new_velocity


func _on_path_find_timer_timeout():
	if is_on_floor():
		DoPathFinding()
