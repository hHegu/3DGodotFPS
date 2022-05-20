extends Spatial

export(Array, Enums.WEAPONS_ENUM) var weapons: Array
export var columns := 3

var margin_x = 0.5
var margin_y = 0.3

var weapon_pickup := preload("res://Objects/WeaponPickup.tscn")

func _ready():
	if not Utils.is_host():
		return

	var spawn_locations = []
	var box_width: float = $Wall.depth - (2 * margin_x)
	var box_height: float = $Wall.height- (2 * margin_y)

	var left_origo = -box_width / 2
	var bottom_origo = -box_height / 2
	
	print(left_origo)
	var rows = ceil(float(weapons.size()) / float(columns))
	
	
	for y in rows:
		for x in columns:
			print((float(x + 1) / float(columns)))
			var loc_x = left_origo + (box_width * float(x)) / float(columns - 1)
			var loc_y = bottom_origo + (box_height * float(y)) / float(rows - 1)
			spawn_locations.append(Vector3(0.15, loc_y, loc_x))
	
	print(spawn_locations)

	for i in weapons.size():
		var location = spawn_locations[i]
		rpc("_add_weapon_pickup", weapons[i], location, Utils.uuid('weapon'))
#		_add_weapon_pickup(weapons[i], location)


remotesync func _add_weapon_pickup(weapon_index: int, position: Vector3, name: String):
	var weapon_i: Weapon = Weapons.get_weapon_instance(weapon_index)
	var weapon_pickup_i: WeaponPickup = weapon_pickup.instance()
	weapon_pickup_i.weapon_i = weapon_i
	weapon_pickup_i.translation = position
	weapon_pickup_i.name = name
	$Wall.add_child(weapon_pickup_i)
