# Handles weapon related signals and UI stuff

extends Node

var current_weapon: Weapon = null
var is_aiming := false

signal current_weapon_changed(new_weapon)
signal camera_aim(is_aiming)
signal weapon_did_damage
signal weapon_was_fired(weapon)


func aim(aiming: bool):
	is_aiming = aiming
	emit_signal("camera_aim", aiming)


func change_weapon(new_weapon: Weapon):
	current_weapon = new_weapon
	emit_signal("current_weapon_changed", new_weapon)


func show_hitmarks(damage: float, type: int):
	emit_signal("weapon_did_damage", damage, type)


func fire():
	emit_signal("weapon_was_fired", current_weapon)
