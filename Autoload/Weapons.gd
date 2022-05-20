extends Node

# Weapons
var w_assault_rifle = preload("res://Weapons/AssaultRifle.tscn")
var w_shotgun = preload("res://Weapons/Shotgun.tscn")
var w_pistol = preload("res://Weapons/Pistol.tscn")
var w_sniper = preload("res://Weapons/Sniper.tscn")

var _weapons_list = {
	Enums.WEAPONS_ENUM.assault_rifle: w_assault_rifle,
	Enums.WEAPONS_ENUM.shotgun: w_shotgun,
	Enums.WEAPONS_ENUM.pistol: w_pistol,
	Enums.WEAPONS_ENUM.sniper: w_sniper,
}

func get_weapon_instance(weapon: int):
	return get_weapon_scene(weapon).instance()


func get_weapon_scene(weapon: int):
	return _weapons_list[weapon]


func get_random_weapon_indexes():
	var w1 = randi() % _weapons_list.size()
	var w2 = randi() % _weapons_list.size()
	while w1 == w2:
		w2 = randi() % _weapons_list.size()
	
	return [w1, w2]
		
