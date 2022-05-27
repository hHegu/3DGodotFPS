extends Spatial

onready var anim: AnimationPlayer = $Model/AnimationPlayer

export var max_health: float = 100.0
var health: float = 100.0
var is_dead = false


func _ready():
	$Model/Head.connect("was_hit", self, "on_hit")
	$Model/Body.connect("was_hit", self, "on_hit")
	reset_health()


func reset_health():
	health = max_health
	is_dead = false


func on_hit(damage: float):
	if is_dead:
		return

	health -= damage
	if health <= 0:
		die()
		yield(get_tree().create_timer(0.01), "timeout")
		WeaponSingleton.show_hitmarks(damage, Enums.HITMARK_TYPE.KILL)


func die():
	anim.play("fall")
	is_dead = true
	$Model/RespawnTimer.start()


func _on_RespawnTimer_timeout():
	reset_health()
	anim.play("stand")
