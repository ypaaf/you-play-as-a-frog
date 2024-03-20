extends "res://Scripts/Trigger.gd"


export var TriggerOnEnter = true
export var TriggerOnExit = false
export var InverseSignal = false


func _init():
	connect("body_entered", self, "_on_PlayerDetector_body_entered")
	connect("body_exited", self, "_on_PlayerDetector_body_exited")


func _on_PlayerDetector_body_entered(body):
	if body.is_in_group("Player") and TriggerOnEnter:
		trigger(!InverseSignal)


func _on_PlayerDetector_body_exited(body):
	if body.is_in_group("Player") and TriggerOnExit:
		trigger(InverseSignal)
