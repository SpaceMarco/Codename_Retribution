extends State
class_name Chase

var player : CharacterBody3D
@export var enemy : CharacterBody3D
@export var stuckRay : RayCast3D
var detection : Detection
@export var area : Area3D

var push_power = 10
var inarea = false
var timer : float = 0.5	
var timeToStuck : float = 2
var distance_to_player
var active = true


func _ready():
	detection = enemy.detection
	enemy.nav.connect("navigation_finished", navigation_finished)
	area.connect("body_entered", body_entered)

func Enter():
	player = Global._get_player()
	enemy.canMove = true
	enemy.move_speed = enemy.CHASE_SPEED
	inarea = false
	

func Exit():
	enemy.move_speed = enemy.MOVE_SPEED
			

func Physics_Update(delta):
	if detection.checkStuck() and not inarea:
		Transitioned.emit(self, "Stuck")
		print("Chase -> Stuck")


func Update(delta):
	distance_to_player = (player.global_position - enemy.global_position).length()

	if distance_to_player < 2 and inarea:
		if timer > 0:
			timer -= delta
		else:
			if detection.checkRays():
				DamagePlayer(enemy.damage)
			timer = 0.5	

func DamagePlayer(damage):
	# [add animation for attack here]
	player.stats.Health -= damage
	var a = player.global_transform.origin
	var b = enemy.global_transform.origin
	player.velocity = (a-b) * push_power
	
func navigation_finished():
	if (get_parent() as StateMachine).current_state == self:
		distance_to_player = (player.global_position - enemy.global_position).length()
		if distance_to_player > 5 or not detection.checkRays():
			inarea = false
			Transitioned.emit(self, "Idle")
			print("Chase -> Idle")
		else:
			inarea = true

func body_entered(body):
	if (get_parent() as StateMachine).current_state == self:
		if body is Player:
			enemy.seeingPlayer = true
			DamagePlayer(enemy.damage)
		else:
			if body is RigidBody3D and body.get_parent().has_node("PickUp"):
				var picked : PickUpObject = body.get_parent().get_node("PickUp")
				
				var a = body.global_transform.origin
				var b = enemy.global_transform.origin
				var dir = (a-b) + (player.global_position + Vector3.RIGHT * 5 * randf_range(-1,1) - b)
				body.apply_central_impulse(dir)
				
				picked.DetectObjects(true)
				picked.remove_object()