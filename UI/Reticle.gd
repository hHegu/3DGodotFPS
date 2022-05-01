extends Control

onready var anim: AnimationPlayer = $AnimationPlayer

func _ready():
	WeaponSingleton.connect("weapon_did_damage", self, "on_weapon_did_damage")


func on_weapon_did_damage(damage: float, type: int):
	anim.stop(true)
	
	$Hitmark.modulate = Color.transparent
	$HitmarkHead.modulate = Color.transparent
	$HitmarkKill.modulate = Color.transparent
	
	match type:
		Enums.HITMARK_TYPE.BODY:
			anim.play("hitmark")
		Enums.HITMARK_TYPE.HEAD:
			anim.play("hitmark_head")
		Enums.HITMARK_TYPE.KILL:
			anim.play("hitmark_kill")
			
	
