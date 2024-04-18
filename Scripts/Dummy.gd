extends "res://Scripts/Enemy.gd"


onready var Player = Main.get_node("Player")

var DMG_DISPLAY_TIME = 2
var label_timer: float = 0


func _ready():
	$AnimatedSprite.play("default")


func _process(delta):
	health = maxHealth
	label_timer = max(0, label_timer - delta)
	$DamageLabel.visible = label_timer


func hurt(damage):
	$DamageLabel.text = "%s" % damage
	label_timer = DMG_DISPLAY_TIME
	
	$PassTrigger.trigger(true)
	$AnimatedSprite.frame = 0
	$AnimatedSprite.flip_h = global_position.direction_to(Player.global_position).x < 0
