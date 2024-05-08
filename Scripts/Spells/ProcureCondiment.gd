extends "res://Scripts/BaseScripts/BouncingSpell.gd"


export var SLIPPY_DURATION: float = 2
export var SELF_SLIPPY_DURATION: float = 1.5
export var SETTLE_SOUND := ""
export var SLIP_SOUND := ""


var condiment_residue = preload("res://Spells/Spell Extras/CondimentResidue.tscn")


func on_settle(body):
	if body is Entity:
		body.Afflict(Effects.slippy, SLIPPY_DURATION)
		Player.MusicPlayer.PlayOnNode(SLIP_SOUND, Player)
		emit_signal("settled")
		return false
	
	if not body is TileMap: 
		emit_signal("settled")
		return false
	
	Player.MusicPlayer.PlayOnNode(SETTLE_SOUND, Player)
	
	emit_signal("settled")
	var residue = condiment_residue.instance()
	get_parent().call_deferred("add_child", residue)
	residue.global_position = global_position
	return false


func animation_finished():
	match $AnimatedSprite.animation:
		"start":
			$AnimatedSprite.play("default")


func on_start():
	var _obj = $AnimatedSprite.connect("animation_finished", self, "animation_finished")
	$AnimatedSprite.play("start")


func try_self_cast(player):
	if player.mana < MANA_COST: 
		queue_free()
		return
	
	player.mana -= MANA_COST
	player.Afflict(Effects.slippy, SELF_SLIPPY_DURATION)
