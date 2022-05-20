extends Spatial

onready var anim_tree: AnimationTree = $AnimationTree
var player: Player
var pivot: Spatial


func _ready():
	player = get_parent()
	pivot = player.get_node("Pivot")

func _physics_process(delta):
	var run_speed = player.velocity.length() / 10.0
	var look_up_scale = (-pivot.rotation_degrees.x / 90 + 1) / 2
	rpc_unreliable("sync_anims", run_speed, look_up_scale)

remote func sync_anims(run_speed, look_up_scale):
	anim_tree["parameters/run_speed/blend_amount"] = player.velocity.length() / 10.0
	anim_tree["parameters/look_up_scale/blend_amount"] = (-pivot.rotation_degrees.x / 90 + 1) / 2
