# Handles the camera

extends Camera

signal weapon_picked_up(weapon)

onready var zoom_tween: Tween = $ZoomTween
onready var pickup_raycast: RayCast = $PickupCast

export(int, LAYERS_3D_PHYSICS) var pickup_mask: int

var initial_fov: float
var zoom_fov: float
var is_aiming: bool

var curr_pickup_raycasted: Weapon setget set_curr_pickup_raycasted

func set_curr_pickup_raycasted(new):
	curr_pickup_raycasted = new
	HUDSingleton.emit_signal("weapon_pickup_raycasted", new)

func _ready():
	initial_fov = fov
	zoom_fov = fov
	WeaponSingleton.connect("camera_aim", self, "on_camera_aim")
	WeaponSingleton.connect("current_weapon_changed", self, "on_current_weapon_changed")


func on_camera_aim(aiming: bool):
	is_aiming = aiming


func on_current_weapon_changed(new_weapon: Weapon):
	zoom_fov = new_weapon.zoom_multiplier * initial_fov


func _process(delta):
	handle_pickup()

func _physics_process(_delta):
	zoom_tween.interpolate_property(
		self,
		'fov',
		fov,
		zoom_fov if is_aiming else initial_fov,
		0.1,
		Tween.TRANS_LINEAR,
		Tween.EASE_OUT
	)
	zoom_tween.start()


func handle_pickup():
	var collider = pickup_raycast.get_collider()
	if collider:
		var pickup_node = collider.get_parent()
		var new_pickup: Weapon = pickup_node.weapon_i
		if !curr_pickup_raycasted or new_pickup.name != curr_pickup_raycasted.name:
			set_curr_pickup_raycasted(new_pickup)
		if Input.is_action_just_pressed("use") and curr_pickup_raycasted:
			emit_signal("weapon_picked_up", new_pickup)
			pickup_node.pickup()
	else:
		if curr_pickup_raycasted != null:
			set_curr_pickup_raycasted(null)
