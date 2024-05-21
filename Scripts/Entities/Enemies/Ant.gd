extends "res://Scripts/BaseScripts/Enemy.gd"


export var CIRCLE_RADIUS = 100
export var BITE_DAMAGE = 10
export var TARGET_COMFORT_RADIUS = 10

export var BITE_FRAME = 0
export var BITE_SOUND = "Nom"

onready var Player = Main.get_node("Player")


enum states {
	STILL,
	CIRCLE,
	SWARM,
	BITE,
	BITING,
}


var state
var randomnum = randf()


func _ready():
	var _c = $AnimatedSprite.connect("frame_changed", self, "frame_changed")


func on_death():
	$AnimatedSprite.play("death")
	yield($AnimatedSprite, "animation_finished")
	emit_signal("death_finished")

func _physics_process(delta):
	if health <= 0:
		return
	set_target()
	state = get_state()
	
	if is_sliding():
		move(0, delta)
		return
	
	
	match state:
		states.STILL:
			$AnimatedSprite.play("still")
		states.CIRCLE:
			$AnimatedSprite.play("walk")
			target_pos = get_circle_position(randomnum, CIRCLE_RADIUS)
			move(target_pos, delta)
			
		states.SWARM:
			move(target_player.global_position, delta)


func get_state():
	if health <= 0:
		return states.STILL
	if target_player == null:
		return states.STILL
	
	if state == states.BITING:
		return states.BITING
		
	if (global_position.distance_to(target_player.global_position) <= ATTACK_RANGE):
		$AnimatedSprite.play("ready_attack")
		Main.get_node("Player/MusicPlayer").PlayOnNode(BITE_SOUND, self)
		return states.BITING
	
	if state == states.SWARM:
		return states.SWARM
		
	if state == states.CIRCLE and global_position.distance_to(target_pos) <= TARGET_COMFORT_RADIUS:
		return states.SWARM
		
	if (global_position.distance_to(target_player.global_position) <= TARGET_RANGE):
		return states.CIRCLE


func animation_finished():
	if health <= 0:
		return
	match $AnimatedSprite.animation:
		"ready_attack":
			for body in $HitCollider.get_overlapping_bodies():
				if !body.is_in_group("Player"): continue
				
				body.hurt(BITE_DAMAGE)
			$AnimatedSprite.play("hit")
		"hit":
			state = states.STILL


func frame_changed():
	if $AnimatedSprite.animation != "hit":
		return
	var frame = $AnimatedSprite.frame
	if frame == BITE_FRAME:
		Player.get_node("MusicPlayer").PlayOnNode(BITE_SOUND, self)
