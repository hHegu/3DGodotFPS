# Handles the camera

extends Camera

onready var zoom_tween: Tween = $ZoomTween

var initial_fov: float
var zoom_fov: float
var is_aiming: bool

func _ready():
	initial_fov = fov
	zoom_fov = fov
	WeaponSingleton.connect("camera_aim", self, "on_camera_aim")
	WeaponSingleton.connect("current_weapon_changed", self, "on_current_weapon_changed")


func on_camera_aim(aiming: bool):
	is_aiming = aiming


func on_current_weapon_changed(new_weapon: Weapon):
	zoom_fov = new_weapon.zoom_multiplier * initial_fov


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
