extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	HUDSingleton.connect("player_was_damaged", self, "_player_was_damaged")
	HUDSingleton.connect("health_was_changed", self, "_health_was_changed")
	pass # Replace with function body.


func _player_was_damaged(damage):
	$HurtBox/AnimationPlayer.play("hurt")


func _health_was_changed(health):
	$PlayerStatusHUD/VBoxContainer/Health.bbcode_text = Utils.center_bbtext(str(health))
	
