extends Spatial

onready var anim_tree: AnimationTree = $AnimationTree
onready var weapon_model: MeshInstance = $Armature/Skeleton/BoneAttachment/Hand/WeaponModel
var player: Player
var pivot: Spatial


func _ready():
	player = get_parent()
	pivot = player.get_node("Pivot")
	set_network_master(player.get_network_master())
	
	# Wait one frame before checking if we are the master of this node
	# Otherwise it won't be defined yet
	yield(get_tree(), "idle_frame")

	set_physics_process(is_network_master())
	
func _process(delta):
	if player.current_weapon:
		weapon_model.mesh = player.current_weapon.get_model().mesh
	
func _physics_process(delta):
	if !is_network_master():
		return

	var run_speed = player.velocity.length() / 10.0
	var look_up_scale = (-pivot.rotation_degrees.x / 90 + 1) / 2
	rpc_unreliable("sync_anims", run_speed, look_up_scale)

remotesync func sync_anims(run_speed, look_up_scale):
	anim_tree["parameters/run_speed/blend_amount"] = run_speed
	anim_tree["parameters/look_up_scale/blend_amount"] = look_up_scale
