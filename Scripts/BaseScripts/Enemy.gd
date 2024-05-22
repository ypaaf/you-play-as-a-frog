tool
extends "res://Scripts/BaseScripts/Entity.gd"

signal death_finished


export var TARGET_RANGE = 300
export var ATTACK_RANGE = 50
export var SPEED = 50
export var SLIP_WALL_DAMAGE = 10
export var SLIP_SPEED_MULT: float = 2
export var SLIP_STUN_DUR = 1
export var STEERING_MULT = 2.5
export var ROTATE_TO_TARGET = false

export var health: float = 10
onready var maxHealth = health

onready var Main = get_node("/root/Main")
onready var rand: RandomNumberGenerator = RandomNumberGenerator.new()
onready var debug = OS.is_debug_build()

onready var curr_speed = SPEED
onready var curr_steering_mult = STEERING_MULT

var velocity = Vector2(0, 0)
var target_player
var target_pos
var sound: String = "Explode"

func animation_finished():
	pass


func get_state():
	assert(false, "Script does not override get_state method!")


func hurt(damage: float, _ignore_hit_delay=false):
	if health <= 0:
		return
	
	health = max(health - damage, 0)
	
	if has_node("HPBar"):
		$HPBar.visible = (health > 0)
	
	if health == 0:
		var player = Main.get_node("Player")
		$CollisionShape2D.disabled = true
		for child in get_children():
			if child is AnimatedSprite:
				child.flip_h = false
		$EffectManager.visible = false
		flip_body(false)
		on_death()
		player.MusicPlayer.PlayOnNode(sound, player)
		yield(self, "death_finished")
		queue_free()


func on_death():
	pass


func _ready():
	if has_node("HPBar"):
		$HPBar.visible = false
	
	add_to_group("Enemy")
	for child in get_children():
		if not child is AnimatedSprite:
			continue
		var _obj = child.connect("animation_finished", self, "animation_finished")


func set_target():
	if target_player and !player_in_sight(target_player):
		target_player = null
		return
	if (target_player == null) or \
	   (global_position.distance_to(target_player.global_position) > TARGET_RANGE):
		 target_player = get_nearest_player()


func on_slip_into_wall():
	pass


func move(_target, delta):
	if Main.Paused or has_effect(Effects.stunned):
		return velocity
	if health <= 0:
		return velocity
	
	if ROTATE_TO_TARGET:
		rotation = Vector2.ZERO.angle_to_point(velocity)
	
	if is_sliding() and velocity.length_squared() != 0:
		slip(delta)
		return velocity
	
	var direction = (_target - global_position).normalized()
	var desired_velocity = direction * curr_speed * slowness_mult
	var steering = (desired_velocity - velocity) * delta * curr_steering_mult
	velocity += steering
	flip_body(velocity.x > 0)
	velocity = move_and_slide(velocity)
	return velocity


func slip(delta):
	var slip_velocity = velocity.normalized() * curr_speed * SLIP_SPEED_MULT
	var body = move_and_collide(slip_velocity * delta)
	
	if body == null:
		return
	
	if body.collider.get_parent().get_children()[0] is TileMap:
		on_slip_into_wall()
		hurt(SLIP_WALL_DAMAGE)
		Cure(Effects.slippy)
		Afflict(Effects.stunned, SLIP_STUN_DUR)
		velocity = Vector2.ZERO


func flip_body(flipped):
	$AnimatedSprite.flip_h = flipped


func get_circle_position(random, circle_radius):
	var circle_center = target_player.global_position
	var angle = random * PI * 2
	var x = circle_center.x + cos(angle) * circle_radius
	var y = circle_center.y + sin(angle) * circle_radius

	return Vector2(x, y)


func get_nearest_player():
	var players = get_tree().get_nodes_in_group("Player")
	var nearest_player
	var lowest_dist = TARGET_RANGE
	
	for player in players:
		var dist = self.global_position.distance_to(player.global_position)
		if dist >= lowest_dist: continue
		
		nearest_player = player
		lowest_dist = dist
	
	if nearest_player == null:
		return
	
	if !player_in_sight(nearest_player):
		return
	
	return nearest_player

func player_in_sight(player):
	if health <= 0:
		return
	if player == null:
		return false
	
	var playerCollision = player.get_node("CollisionShape2D")
	if playerCollision == null:
		return false
	
	var playerPos = player.global_position
	var collisionRadius = playerCollision.shape.radius
	var collisionHeight = playerCollision.shape.height
	
	var targetPositions = [Vector2(
			playerPos.x-collisionRadius,
			playerPos.y-(collisionHeight)
		),Vector2(
			playerPos.x+collisionRadius,
			playerPos.y-(collisionHeight)
		),Vector2(
			playerPos.x-collisionRadius,
			playerPos.y+(collisionHeight)
		),Vector2(
			playerPos.x+collisionRadius,
			playerPos.y+(collisionHeight)
		)]
	
	for p in targetPositions:
		var rayResult = Main.cast_ray(self.global_position, p, 0b00000000_00000000_00000000_00001001, [self])
		if not rayResult.has("position"):
			continue
		if rayResult.collider == player:
			return true
	
	return false
