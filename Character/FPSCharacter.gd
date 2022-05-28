# The main player controller
extends KinematicBody

class_name Player

onready var pivot: Spatial = $Pivot
onready var recoil_pivot: Spatial = $Pivot/RecoilPivot
onready var hand: Spatial = $Pivot/RecoilPivot/WeaponPivot/Hand
onready var anim: AnimationPlayer = $Pivot/RecoilPivot/WeaponPivot/AnimationPlayer
onready var body: CollisionShape = $Body
onready var crouch_tween: Tween = $CrouchTween
onready var recoil_tween: Tween = $RecoilTween
onready var coyote_timer: Timer = $CoyoteTimer
onready var buffered_jump_timer: Timer = $BufferedJumpTimer
onready var camera: Camera = $Pivot/RecoilPivot/Camera
onready var network_position_tween: Tween = $NetworkUtils/PositionTween

export var gravity := -20.0
export var max_speed := 8.0
export var aim_move_speed := 4.0
export var crouch_move_speed := 4.0
export var mouse_sensitivity := 0.002  # radians/pixel
export var jump_strength := 10.0
export var crouch_height := 0.5

export(Array, Enums.WEAPONS_ENUM) var weapons: Array

export(Material) var red_team_color
export(Material) var blue_team_color

var current_weapon: Weapon
var current_weapon_index: int = 0
var prev_weapon_index: int = 1

var grounded := true

export var is_controlled_by_player: bool
var initial_body_height: float
var initial_pivot_height: float
var velocity := Vector3()
var crouch_progress := 1.0
var is_crouching := false
var has_jumped := false

# Player information
var player_max_health: float = 100.0
remotesync var player_health: float = 100.0 setget set_player_health

# Network related variables
puppet var puppet_transform: Transform setget puppet_transform_set
puppet var puppet_velocity: Vector3

var weapon_pickup = preload("res://Objects/WeaponPickup.tscn")

func _ready():
	WeaponSingleton.connect("weapon_was_fired", self, "on_weapon_was_fired")
	$BodyArea.connect("was_hit", self, "take_damage")
	$HeadArea.connect("was_hit", self, "take_damage")
	camera.connect("weapon_picked_up", self, "_weapon_picked_up")
	set_physics_process(false)
	set_process(false)

	# Wait one frame before checking if we are the master of this node
	# Otherwise it won't be defined yet
	yield(get_tree(), "idle_frame")

	set_physics_process(is_network_master())
	set_process(is_network_master())

	initial_body_height = body.shape.height
	initial_pivot_height = pivot.translation.y


	for weapon in weapons:
		var weapon_i = Weapons.get_weapon_instance(weapon)
		hand.add_child(weapon_i)
		weapon_i.set_network_master(get_network_master())

	current_weapon = hand.get_child(0)
	
	$Pivot/RecoilPivot/WeaponPivot.set_network_master(get_network_master())
	
	if is_network_master() and current_weapon:
		WeaponSingleton.change_weapon(current_weapon)

	_make_body_visible_for_other_than_owner()
	set_team_color()


func _make_body_visible_for_other_than_owner():
	if not is_network_master():
		$lowpoly_human/Armature/Skeleton/Cube.layers = 1
		$lowpoly_human/Armature/Skeleton/BoneAttachment/Hand/WeaponModel.layers = 1


func set_player_health(new_health):
	if is_network_master():
		HUDSingleton.set_hud_healt(new_health)

	# If player is already dead
	if player_health == 0:
		player_health = max(0, new_health)
		return

	player_health = max(0, new_health)

	if player_health == 0:
		death()




func death():
	if is_network_master():
		toggle_player_control(false)
		toggle_player_camera(false)
		GameMaster.emit_signal("player_died", get_network_master())

	visible = false
	body.disabled = true


func get_input():
	var input_dir = Vector3()
	# desired move in camera direction
	if Input.is_action_pressed("up"):
		input_dir += -global_transform.basis.z
	if Input.is_action_pressed("down"):
		input_dir += global_transform.basis.z
	if Input.is_action_pressed("left"):
		input_dir += -global_transform.basis.x
	if Input.is_action_pressed("right"):
		input_dir += global_transform.basis.x
	return input_dir.normalized()


func _unhandled_input(event):
	if not is_network_master() or not is_controlled_by_player:
		return

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		pivot.rotation.x = clamp(pivot.rotation.x, deg2rad(-90), deg2rad(90))


func get_movement_speed():
	if is_crouching:
		return crouch_move_speed
	if WeaponSingleton.is_aiming:
		return aim_move_speed
	return max_speed


func _process(_delta):
	if Input.is_action_just_pressed("previous_weapon"):
		change_weapon(prev_weapon_index)
	
	var pressed_weapon_id = get_pressed_weapon_id()
	if pressed_weapon_id != null:
		change_weapon(pressed_weapon_id)


func get_pressed_weapon_id():
	for i in 3:
		if Input.is_action_just_pressed("weapon_%s" % str(i + 1)):
			return i
	return null


func _physics_process(delta):
	if not is_network_master():
		if not network_position_tween.is_active():
			move_and_slide(puppet_velocity, Vector3.UP, true)
		return
	
	send_location_over_network()
	crouch()
	
	if grounded and not is_on_floor():
		coyote_timer.start()
	
	if is_on_floor() and not grounded:
		has_jumped = false
	
	grounded = is_on_floor()
	
	velocity.y += gravity * delta
	var speed = get_movement_speed()
	var desired_velocity = get_input() * speed

	if grounded:
		if desired_velocity.length() > 0:
			anim.play("walk")
		else:
			anim.play("idle")

	jump()

	velocity.x = desired_velocity.x
	velocity.z = desired_velocity.z
	velocity = move_and_slide(velocity, Vector3.UP, true)


func jump():
	var is_jump_pressed = Input.is_action_just_pressed("jump")
	var is_jump_buffered = not buffered_jump_timer.is_stopped()
	var is_coyote = not coyote_timer.is_stopped()
	
	if not grounded and is_jump_pressed:
		buffered_jump_timer.start()
	
	if not grounded and not is_coyote:
		return
	
	if (is_jump_pressed or is_jump_buffered) and not has_jumped:
		has_jumped = true
		coyote_timer.stop()
		velocity.y += jump_strength
		anim.play("jump")


func crouch():
	if Input.is_action_pressed("crouch"):
		is_crouching = true
		crouch_tween.interpolate_property(
			self, 'crouch_progress', crouch_progress, 1, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN
		)
	else:
		is_crouching = false
		crouch_tween.interpolate_property(
			self, 'crouch_progress', crouch_progress, 0, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN
		)

	body.shape.height = initial_body_height - (crouch_height * crouch_progress)
	pivot.translation.y = initial_pivot_height - (crouch_height * crouch_progress)
	crouch_tween.start()


func change_weapon(weapon_index: int):
	if weapons.size() < weapon_index + 1:
		return

	# If we have only one weapon or if we have no weapons, escape function
	if !current_weapon and hand.get_child_count() == 0 or hand.get_child_count() == 1:
		return

	if !current_weapon or current_weapon.name != hand.get_child(weapon_index).name:
		prev_weapon_index = current_weapon_index
		current_weapon = hand.get_child(weapon_index)
		current_weapon_index = weapon_index
		WeaponSingleton.change_weapon(current_weapon)
		rpc("sync_current_weapon", weapon_index)


remote func sync_current_weapon(weapon_index):
	current_weapon = hand.get_child(weapon_index)
	current_weapon_index = weapon_index


var vertical_target_recoil: float = 0
var horizontal_target_recoil: float = 0
# Handles vertical recoil
var pivot_target_vector = Vector3(0, 0, 0)
# Handles horizontal recoil
var self_target_vector = Vector3(0, 0, 0)

func on_weapon_was_fired(weapon: Weapon):
	if not is_network_master():
		return

	var recoil = weapon.get_recoil()
	vertical_target_recoil = recoil_pivot.rotation.x + deg2rad(recoil.y)
	horizontal_target_recoil =  rotation.y + deg2rad(recoil.x)

	self_target_vector = Vector3(0, horizontal_target_recoil, 0)
	pivot_target_vector = Vector3(vertical_target_recoil, 0, 0)

	recoil_tween.stop_all()
	if abs(recoil.y) > 0:
		recoil_tween.interpolate_property(recoil_pivot, "rotation", recoil_pivot.rotation, pivot_target_vector, weapon.recoil_time, Tween.TRANS_QUINT, Tween.EASE_OUT)
	if abs(recoil.x) > 0:
		recoil_tween.interpolate_property(self, "rotation", rotation, self_target_vector, weapon.recoil_time, Tween.TRANS_QUINT, Tween.EASE_OUT)
	recoil_tween.start()


func send_location_over_network():
	rset_unreliable("puppet_transform", global_transform)
	rset_unreliable("puppet_velocity", velocity)


func _on_RecoilTween_tween_all_completed():
	# Reset recoil pivot to 0 while assigning its recoil to the main pivot. Purkka hack to make recoil work
	pivot.rotation.x = pivot.rotation.x + recoil_pivot.rotation.x
	recoil_pivot.rotation.x = 0


puppet func puppet_transform_set(new_transform: Transform):
	puppet_transform = new_transform
	network_position_tween.interpolate_property(self, "global_transform", global_transform, new_transform, 0.05)
	network_position_tween.start()


func toggle_player_control(is_enabled: bool):
	is_controlled_by_player = is_enabled
	set_physics_process(is_enabled)
	set_process(is_enabled)


func toggle_player_camera(camera_enabled: bool):
	camera.current = camera_enabled
	if camera_enabled:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


remotesync func reset_player():
	set_player_health(player_max_health)


func take_damage(damage) -> int:
	var is_lethal = player_health - damage <= 0
	var hitmark_type = Enums.HITMARK_TYPE.KILL if is_lethal else Enums.HITMARK_TYPE.BODY
	rpc("_take_damage_sync", damage)
	return hitmark_type


master func _take_damage_sync(damage):
	rset("player_health", player_health - damage)
	HUDSingleton.show_damage_effect(damage)


func _weapon_picked_up(weapon_i: Weapon):
	var old_weapon = hand.get_child(current_weapon_index)
	hand.add_child_below_node(old_weapon, weapon_i)
	hand.remove_child(old_weapon)
	weapon_i.set_network_master(get_network_master())
	WeaponSingleton.change_weapon(weapon_i)
	current_weapon = weapon_i

	rpc("drop_old_weapon", Utils.uuid('weapon_drop'), old_weapon.weapon_id, old_weapon.get_ammo_stats())
	rpc("sync_wepon_pickup", weapon_i.weapon_id, current_weapon_index)

remotesync func drop_old_weapon(weapon_drop_id, weapon_enum_id, weapon_ammo_stats):
	var weapon_pickup_i: WeaponPickup = weapon_pickup.instance()
	weapon_pickup_i.name = weapon_drop_id
	weapon_pickup_i.weapon_i = Weapons.get_weapon_instance(weapon_enum_id)
	weapon_pickup_i.weapon_i.apply_ammo(weapon_ammo_stats)
	weapon_pickup_i.weapon_i.name = "w_" + weapon_drop_id
	weapon_pickup_i.transform.origin = hand.global_transform.origin
	weapon_pickup_i.weapon_dropped()
	get_tree().get_root().add_child(weapon_pickup_i)
	var forward_vector = Vector3.FORWARD.rotated(Vector3.UP, rotation.y) * -1
	weapon_pickup_i.look_at(forward_vector * 10, Vector3.UP)
	weapon_pickup_i.apply_impulse(Vector3.ZERO, forward_vector * -1.2)
	weapon_pickup_i.apply_torque_impulse(forward_vector * 0.1)

remote func sync_wepon_pickup(weapon_enum_id, weapon_index):
	var weapon_i = Weapons.get_weapon_instance(weapon_enum_id)
	var old_weapon = hand.get_child(current_weapon_index)
	hand.add_child_below_node(old_weapon, weapon_i)
	hand.remove_child(old_weapon)
	weapon_i.set_network_master(get_network_master())


func set_team_color():
	var team_material = blue_team_color if Lobby.players[get_network_master()].team == Enums.TEAMS.BLUE else red_team_color
	$lowpoly_human/Armature/Skeleton/Cube.material_override = team_material
