extends KinematicBody2D


export var TARGET_RANGE = 300
export var ATTACK_RANGE = 50
export var SPEED = 50
var CIRCLE_RADIUS = 40
export var SLAM_DAMAGE = 10

onready var rand = RandomNumberGenerator.new()

var velocity = Vector2(0, 0)
var target

enum {
	STILL,
	INCH,
	ATTACK,
	ATTACKING,
}


var state = INCH


func _ready():
	$AnimatedSprite.connect("animation_finished", self, "animation_finished")
	
	
func _physics_process(delta):
	if (target == null) or \
	   (global_position.distance_to(target.global_position) > TARGET_RANGE):
		 target = get_nearest_player()
	if target == null: state = STILL
	
	# i know this can be done way better, you can fix it if you want
	else:
		if state == ATTACKING:
			pass
		else: if (global_position.distance_to(target.global_position) > ATTACK_RANGE):
			state = INCH
		else: if state != ATTACKING:
			state = ATTACK
	
	
	match state:
		STILL:
			$AnimatedSprite.play("still")
		INCH:
			$AnimatedSprite.play("walking")
			move(target.global_position, delta)
		ATTACK:
			$AnimatedSprite.play("raise")
			state = ATTACKING
	

func animation_finished():
	match $AnimatedSprite.animation:
		"raise":
			for body in $SlamCollider.get_overlapping_bodies():
				if !body.is_in_group("Player"): continue
				
				body.health -= SLAM_DAMAGE
			$AnimatedSprite.play("hit")
		"hit":
			state = STILL
		


func move(target, delta):
	var direction = (target - global_position).normalized()
	var desired_velocity = direction * SPEED
	var steering = (desired_velocity - velocity) * delta * 2.5
	velocity += steering
	if velocity.x > 0: $AnimatedSprite.flip_h = true
	if velocity.x < 0: $AnimatedSprite.flip_h = false
	velocity = move_and_slide(velocity)


func get_circle_position(target, random):
	var circle_center = target.global_position
	var angle = random * PI * 2
	var x = circle_center + cos(angle) * CIRCLE_RADIUS
	var y = circle_center + sin(angle) * CIRCLE_RADIUS
	
	return Vector2(x, y)


func get_nearest_player():
	var players = get_tree().get_nodes_in_group("Player")
	var nearest_player
	var lowest_dist = ATTACK_RANGE
	
	for player in players:
		var dist = self.global_position.distance_to(player.global_position)
		if dist >= lowest_dist: continue
		
		nearest_player = player
		lowest_dist = dist
	
	return nearest_player