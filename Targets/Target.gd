extends Spatial

export var damage_multiplier := 1.0
export (Enums.HITMARK_TYPE) var hitmark_type

signal was_hit(damage)

func take_damage(damage: float):
	emit_signal("was_hit", damage * damage_multiplier)
	return hitmark_type
