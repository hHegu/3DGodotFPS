# The main player controller
extends KinematicBody

onready var pivot: Spatial = $Pivot
onready var recoil_pivot: Spatial = $Pivot/RecoilPivot
onready var hand: Spatial = $Pivot/RecoilPivot/WeaponPivot/Hand
onready var anim: AnimationPlayer = $Pivot/RecoilPivot/WeaponPivot/AnimationPlayer
onready var body: CollisionShape = $Body
onready var crouch_tween: Tween = $CrouchTween
onready var recoil_tween: Tween = $RecoilTween
onready var coyote_timer: Timer = $CoyoteTimer
onready var buffered_jump_timer: Timer = $BufferedJumpTimer

onready var network_position_tween: Tween = $NetworkUtils/PositionTween

export var gravity := -20.0
export var max_speed := 8.0
export var aim_move_speed := 4.0
export var crouch_move_speed := 4.0
export var mouse_sensitivity := 0.002  # radians/pixel
export var jump_strength := 10.0
export var crouch_height := 0.5

export (Resource) var weapon_1
export (Resource) var weapon_2

var current_weapon: Weapon
var current_weapon_index: int = 0

var grounded := true

var is_player_enabled: bool setget set_is_player_enabled
var initial_body_height: float
var initial_pivot_height: float
var velocity := Vector3()
var crouch_progress := 1.0
var is_crouching := false
var has_jumped := false

# Player information
remotesync var player_name: String

# Network related variables
puppet var puppet_transform: Transform setget puppet_transform_set
puppet var puppet_velocity: Vector3


func _ready():
	WeaponSingleton.connect("weapon_was_fired", self, "on_weapon_was_fired")
	get_tree().connect("network_peer_connected", self, "_player_connected")

	initial_body_height = body.shape.height
	initial_pivot_height = pivot.translation.y
#	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var weapon_1_i: Weapon = weapon_1.instance()
	var weapon_2_i: Weapon = weapon_2.instance()

	hand.add_child(weapon_1_i)
	hand.add_child(weapon_2_i)

	current_weapon = weapon_1_i
	WeaponSingleton.change_weapon(weapon_1_i)

# Synchronize player values when a new player joins
func _player_connected(id):
	if is_network_master():
		rset('player_name', player_name)

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
	if not is_network_master() or not is_player_enabled:
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
	if Input.is_action_just_pressed("switch_weapon"):
		change_weapon(0 if current_weapon_index == 1 else 1)


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
	if current_weapon.weapon_name != hand.get_child(weapon_index).weapon_name:
		current_weapon = hand.get_child(weapon_index)
		current_weapon_index = weapon_index
		WeaponSingleton.change_weapon(current_weapon)


var vertical_target_recoil: float = 0
var horizontal_target_recoil: float = 0
# Handles vertical recoil
var pivot_target_vector = Vector3(0, 0, 0)
# Handles horizontal recoil
var self_target_vector = Vector3(0, 0, 0)

func on_weapon_was_fired(weapon: Weapon):
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


func puppet_transform_set(new_transform: Transform):
	puppet_transform = new_transform
	network_position_tween.interpolate_property(self, "global_transform", global_transform, new_transform, 0.1)
	network_position_tween.start()


func set_is_player_enabled(is_enabled: bool):
	is_player_enabled = is_enabled
	$Pivot/RecoilPivot/Camera.current = is_enabled
	set_physics_process(is_enabled)
	set_process(is_enabled)
	current_weapon.set_physics_process(is_enabled)
	current_weapon.set_process(is_enabled)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if is_enabled else Input.MOUSE_MODE_VISIBLE)
