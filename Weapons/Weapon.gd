extends Spatial
class_name Weapon

export var weapon_name := "NOT_NAMED"
export(Enums.WEAPONS_ENUM) var weapon_id = Enums.WEAPONS_ENUM.pistol

## Damage per bullet
export var damage := 10.0
## Shots per second
export var fire_rate := 0.5
export var is_automatic := false
# If true, sniper scope is shown on ads
export var is_scoped := false

## Bullets disappear after this range
export var effective_range := 2000.0

## How much bullets randomly spread
export var bullet_spread := 0.0
## How the spread behaves over time
export (Curve) var spread_over_time: Curve
## How long it takes to traverse the spread_over_time curve
export var spread_time := 1.0
## How long it takes to recover accuracy after firing
export var spread_recovery_time := 0.5

## Size of the clip
export var clip_size := 30
## Max amount of ammo the weapon can have in reserve
export var max_ammo := 120
## Current amount of ammo in the clip
var clip_ammo: int = -1
## Current amount of ammo not in the clip
var ammo: int = -1

## aim down sights fov multiplier
export var zoom_multiplier := 0.6

## Recoil vector in degrees
export var recoil := Vector2(0, 0)
## Time it takes to finish recoil animation
export var recoil_time := 0.01

## Weapon position when aimed down sights
export var hand_aim_position: Vector3

## How many bullets are fired per shot. Used in Shotguns
export var bullets_fired := 1

## Multiplier for bullet spread when aiming down sights
export var ads_spread_multiplier := 0.5
## Multiplier for recoil when aiming down sights
export var ads_recoil_multiplier := 0.5

var is_current := false
var is_reloading := false

onready var anim: AnimationPlayer = $AnimationPlayer
onready var fire_rate_timer: Timer
onready var spread_timer: Timer
onready var spread_recovery_timer: Timer

var bullet_effect = preload("res://BulletEffect.tscn")
var bullet_trail = preload("res://bullet.tscn")


func _ready():
	if clip_ammo == -1 or ammo == -1:	
		ammo = max_ammo
		clip_ammo = clip_size

	fire_rate_timer = Timer.new()
	spread_timer = Timer.new()
	spread_recovery_timer = Timer.new()

	fire_rate_timer.one_shot = true
	spread_timer.one_shot = true
	spread_recovery_timer.one_shot = true

	add_child(fire_rate_timer)
	add_child(spread_timer)
	add_child(spread_recovery_timer)

	spread_recovery_timer.connect("timeout", self, "_on_SpreadRecoveryTimer_timeout")
	WeaponSingleton.connect("current_weapon_changed", self, "_current_weapon_changed")
	WeaponSingleton.connect("camera_aim", self, "_camera_aim")


func _current_weapon_changed(curr: Weapon):
	if is_network_master():
		rpc("enable_weapon", curr.name)


remotesync func enable_weapon(current_weapon_name):
	WeaponSingleton.aim(false)
	is_current = current_weapon_name == name
	anim.stop()
	rpc("play_anim_synced", "switch_to")
	is_reloading = false
	visible = is_current


func _process(_delta):
	if not is_network_master() or HUDSingleton.is_paused:
		return

	if get_owner_player():
		if not get_owner_player().is_controlled_by_player:
			return

	if not is_current or anim.current_animation == 'switch_to':
		return

	var camera: Camera = get_viewport().get_camera()
	var input_event = (
		Input.is_action_pressed("fire")
		if is_automatic
		else Input.is_action_just_pressed("fire")
	)

	if Input.is_action_just_pressed("reload"):
		reload()

	if input_event && fire_rate_timer.is_stopped() && ! is_reloading:
		if ! handle_ammo():
			if ammo <= 0:
				return
			reload()
			return
		WeaponSingleton.fire()
		anim.stop(true)
		rpc("play_anim_synced", "fire_aim" if WeaponSingleton.is_aiming else "fire")
		fire_rate_timer.start(fire_rate)

		var center := get_viewport().size / 2

		if spread_timer.is_stopped() and spread_recovery_timer.is_stopped():
			spread_timer.start(spread_time)

		spread_recovery_timer.start(spread_recovery_time)

		var is_recovering_and_max_spread = (
			spread_timer.is_stopped()
			and ! spread_recovery_timer.is_stopped()
		)

		var current_spread_multiplier := (
			1.0
			if is_recovering_and_max_spread
			else spread_over_time.interpolate_baked(
				(spread_timer.wait_time - spread_timer.time_left) / spread_timer.wait_time
			)
		)

		for n in bullets_fired:
			var spread_vector: Vector2 = (
				get_random_point_in_a_circle(get_spread())
				* current_spread_multiplier
			)
			var spread_target := Vector3(
				camera.project_ray_normal(center).x + spread_vector.x,
				camera.project_ray_normal(center).y + spread_vector.y,
				camera.project_ray_normal(center).z + spread_vector.x
			)

			var from := camera.project_ray_origin(center)
			var to := from + spread_target * effective_range

			fire_bullet(from, to)


func get_random_point_in_a_circle(r: float) -> Vector2:
	randomize()
	var angle = randf() * PI * 2
	randomize()
	var cosrandom = randf()
	randomize()
	var sinrandom = randf()
	return Vector2(cos(angle) * r * cosrandom, sin(angle) * r * sinrandom)


func fire_bullet(from: Vector3, to: Vector3) -> void:
	var player = get_owner_player()
	var result = get_world().direct_space_state.intersect_ray(from, to, [self, player])

	if result and result.collider and result.collider.has_method('take_damage'):
		var hitmark_type = result.collider.take_damage(damage)
		WeaponSingleton.show_hitmarks(damage, hitmark_type)

	var bullet_effect_to = to if not result.has('position') else result.position
	rpc("_show_bullet_trail", from, bullet_effect_to, result and result.has('position'))


remotesync func _show_bullet_trail(from, to, spawn_effect: bool):
	var bullet_i = bullet_trail.instance()
	bullet_i.target_position = to
	bullet_i.transform.origin = from
	get_tree().root.add_child(bullet_i)

	if spawn_effect:
		var effect_i: Particles = bullet_effect.instance()
		effect_i.transform.origin = to
		get_tree().root.add_child(effect_i)


func handle_ammo() -> bool:
	var can_fire = clip_ammo > 0
	if can_fire:
		clip_ammo -= 1
	return can_fire


func reload():
	if clip_ammo == clip_size or ammo == 0:
		return
	is_reloading = true
	rpc("play_anim_synced", "reload")


func reload_finished():
	var bullets_reduced := int(min(clip_size - clip_ammo, ammo))
	clip_ammo = bullets_reduced + clip_ammo
	ammo -= bullets_reduced
	is_reloading = false


func get_recoil() -> Vector2:
	if WeaponSingleton.is_aiming:
		return recoil * ads_recoil_multiplier
	return recoil


func get_spread() -> float:
	if WeaponSingleton.is_aiming:
		return bullet_spread * ads_spread_multiplier
	return bullet_spread


func _on_SpreadRecoveryTimer_timeout():
	# Reset spread when recovered
	spread_timer.stop()


remotesync func play_anim_synced(anim_name):
	anim.play(anim_name)


func get_owner_player():
	return Players.get_player(get_network_master())


# For syncing ammo on weapon pickups
func get_ammo_stats():
	return {"clip_ammo": clip_ammo, "ammo": ammo}

func apply_ammo(ammo_stats):
	clip_ammo = ammo_stats.clip_ammo
	ammo = ammo_stats.ammo

func _camera_aim(is_aiming: bool):
	$Model.visible = !is_aiming or !is_scoped
