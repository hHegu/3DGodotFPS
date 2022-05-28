extends RigidBody

class_name WeaponPickup

onready var model: MeshInstance = $Model
onready var despawn_timer: Timer = $DespawnTimer
var weapon_i: Weapon
signal picked_up
var is_dropped := false

func _ready():
	var weapon_model: MeshInstance = weapon_i.get_node("Model")
	model.mesh = weapon_model.mesh
	model.scale = weapon_model.scale
	
	var is_host = Utils.is_host()
	
	if not is_host:
		mode = RigidBody.MODE_STATIC
	set_process(is_host)
	set_physics_process(is_host)
	
	if is_host and is_dropped:
		despawn_timer.start()
	


func pickup():
	rpc("sync_pickup")


remotesync func sync_pickup():
	emit_signal("picked_up")
	queue_free()



func weapon_dropped():
	if Utils.is_host():
		mode = RigidBody.MODE_RIGID
		is_dropped = true


func _physics_process(delta):
	if !sleeping:
		rpc_unreliable("sync_position", global_transform)


remote func sync_position(newPos: Transform):
	global_transform = newPos


remotesync func despawn():
	$AnimationPlayer.play("despawn")

func _on_DespawnTimer_timeout():
	print('DESPAWN!')
	rpc("despawn")
