extends RigidBody

class_name WeaponPickup

onready var model: MeshInstance = $Model
var weapon_i: Weapon

func _ready():
	var weapon_model: MeshInstance = weapon_i.get_node("Model")
	model.mesh = weapon_model.mesh
	model.scale = weapon_model.scale
	
	if not Utils.is_host():
		mode = RigidBody.MODE_STATIC
	set_process(Utils.is_host())
	set_physics_process(Utils.is_host())


func pickup():
	rpc("sync_pickup")


remotesync func sync_pickup():
	queue_free()


func _physics_process(delta):
	if !sleeping:
		rpc_unreliable("sync_position", global_transform)


remote func sync_position(newPos: Transform):
	global_transform = newPos
