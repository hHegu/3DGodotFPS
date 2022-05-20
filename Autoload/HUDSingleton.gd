extends Node


signal player_was_damaged(damage)
signal health_was_changed(health)
signal score_changed(blue_score, red_score)
signal weapon_pickup_raycasted(weapon)

var is_paused := false

func show_damage_effect(damage):
	emit_signal("player_was_damaged", damage)

func set_hud_healt(health):
	emit_signal("health_was_changed", health)
