extends Spatial

export(Enums.WEAPONS_ENUM) var weapon: int
var weapon_pickup := preload("res://Objects/WeaponPickup.tscn")

func _ready():
	$AnimationPlayer.play("hover")
	if not Utils.is_host():
		return

	rpc("_add_weapon_pickup", weapon, Utils.uuid('weapon'))


remotesync func _add_weapon_pickup(weapon_index: int, name: String):
	var weapon_i: Weapon = Weapons.get_weapon_instance(weapon_index)
	var weapon_pickup_i: WeaponPickup = weapon_pickup.instance()
	weapon_pickup_i.weapon_i = weapon_i
	weapon_pickup_i.name = name
	$PickupPos.add_child(weapon_pickup_i)
	if Utils.is_host():
		weapon_pickup_i.connect("picked_up", self, "_picked_up")

func _picked_up():
	$RespawnTimer.start()


func _on_RespawnTimer_timeout():
	rpc("_add_weapon_pickup", weapon, Utils.uuid('weapon'))
