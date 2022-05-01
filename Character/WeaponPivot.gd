# Handles aiming and weapon sway

extends Spatial

var mouse_mov_x: float
var sway_treshold := 3.0
var sway_lerp := 5.0

var aiming := false

export var sway_left: Vector3
export var sway_right: Vector3
export var sway_normal: Vector3

export var hand_target_pos: Vector3
var hand_initial_pos: Vector3

onready var hand: Spatial = $Hand
onready var aim_tween: Tween = $AimTween


func _ready():
	hand_initial_pos = hand.transform.origin


func _input(event):
	if event is InputEventMouseMotion:
		mouse_mov_x = -event.relative.x


func _physics_process(delta):
	aim()

	if mouse_mov_x == null:
		return

	if mouse_mov_x > sway_treshold && ! aiming:
		rotation = rotation.linear_interpolate(sway_left, sway_lerp * delta)
	elif mouse_mov_x < -sway_treshold && ! aiming:
		rotation = rotation.linear_interpolate(sway_right, sway_lerp * delta)
	else:
		rotation = rotation.linear_interpolate(sway_normal, sway_lerp * delta)


func aim():
	var is_reloading = WeaponSingleton.current_weapon.is_reloading

	aiming = Input.is_action_pressed("aim") and not is_reloading

	if aiming and ! WeaponSingleton.is_aiming:
		WeaponSingleton.aim(true)
	if ! aiming and WeaponSingleton.is_aiming:
		WeaponSingleton.aim(false)

	if aiming:
		var hand_target = WeaponSingleton.current_weapon.hand_aim_position
		aim_tween.interpolate_property(
			hand,
			'translation',
			hand.transform.origin,
			hand_target,
			0.051,
			Tween.TRANS_LINEAR,
			Tween.EASE_OUT
		)
	else:
		aim_tween.interpolate_property(
			hand,
			'translation',
			hand.transform.origin,
			hand_initial_pos,
			0.051,
			Tween.TRANS_LINEAR,
			Tween.EASE_OUT
		)
	aim_tween.start()
