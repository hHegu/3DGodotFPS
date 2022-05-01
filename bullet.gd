extends KinematicBody

var target_position: Vector3
var bullet_speed := 100.0
onready var timer: Timer = $Timer


func _physics_process(_delta):
	var dir = (target_position - global_transform.origin).normalized()

	move_and_slide(dir * bullet_speed, Vector3.UP) 
	if global_transform.origin.distance_to(target_position) < 1:
		queue_free()


#
#export var max_x := 2.0
#export var min_x := -2.0
#export var bullet_speed := 1.0
#
#var going_right := true
#var is_paused := false
## Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _physics_process(delta):
#	if timer.time_left > 0:
#		return
#
#	if global_transform.origin.x > max_x && going_right:
#		going_right = false
#		timer.start()
#	if global_transform.origin.x < min_x && !going_right:
#		going_right = true
#		timer.start()		
#
#	move_and_slide((Vector3.RIGHT if going_right else Vector3.LEFT) * bullet_speed, Vector3.UP)
#
#
#
func _on_Timer_timeout():
	queue_free()
