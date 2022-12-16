extends KinematicBody2D
class_name Player

signal grounded_update(is_grounded)
signal health_updated(health) 
signal killed() 

const UP = Vector2(0, -1)
const DROP_THRU_BIT = 1
const SLOPE_STOP_THRESHOLD = 64.0
const BOUNCE_VELOCITY = -300

export (float) var max_health = 100 
onready var healthBarNode = get_node("%HealthBar") 
onready var health = max_health setget _set_health 

var velocity = Vector2()
var move_speed = 5 * Globals.UNIT_SIZE
var gravity
var max_jump_velocity
var min_jump_velocity  
var is_grounded
var is_jumping = false
var move_direction

var max_jump_height = 2.1 * Globals.UNIT_SIZE
var min_jump_height = 0.7 * Globals.UNIT_SIZE
var jump_duration = 0.5

onready var raycasts = $Body/Raycasts
onready var bounce_raycasts = $Body/BounceRaycasts
onready var anim_player = $Body/Sprite/AnimationPlayer
onready var standing_collision = $StandingShape
onready var crouching_collision = $CrouchingShape
onready var remoteTransform2D = $RemoteTransform2D

onready var invulnerability_timer = $InvulnerabilityTimer
onready var coyote_timer = $CoyoteTimer
onready var jump_buffer = $JumpBuffer
onready var effects_animation = $EffectsAnimation 

func _ready():
	connect("health_updated", healthBarNode, "_on_health_bar_updated")
	Globals.emit_signal("refill_health")
	gravity = 3.5 * max_jump_height / pow(jump_duration, 2)
	max_jump_velocity = -sqrt(2 * gravity * max_jump_height)
	min_jump_velocity = -sqrt(2 * gravity * min_jump_height)

func _input(event):
	if event.is_action_pressed("jump"):
		if is_on_floor() || !coyote_timer.is_stopped():
			coyote_timer.stop()
			jump()
		else:
			jump_buffer.start()

func _apply_gravity(delta): #yet to add final step of coyote jump#
	velocity.y += gravity * delta

func _apply_movement(delta):
	if is_jumping && velocity.y >= 0:
		is_jumping = false
	
	var snap = Vector2.DOWN * 32 if !is_jumping else Vector2.ZERO
	
	if move_direction == 0 && abs(velocity.x) < SLOPE_STOP_THRESHOLD:
		velocity.x = 0
	
	var stop_on_slope = true if get_floor_velocity().x == 0 else false
	
	var was_on_floor = is_on_floor()
	_check_bounce(delta)
	velocity = move_and_slide_with_snap(velocity, snap, UP, stop_on_slope)
	if !is_on_floor() && was_on_floor && !is_jumping:
		coyote_timer.start()
	if is_on_floor() && !jump_buffer.is_stopped():
		jump_buffer.stop()
		jump()
	
	var was_grounded = is_grounded
	is_grounded = is_on_floor()
	
	if was_grounded == null || is_grounded != was_grounded:
		emit_signal("grounded_update", is_grounded)

	is_grounded = !is_jumping && get_collision_mask_bit(DROP_THRU_BIT) && _check_is_grounded()

func _handle_move_input():
	move_direction = -int(Input.is_action_pressed("move_left")) + int(Input.is_action_pressed("move_right"))
	velocity.x = lerp(velocity.x, move_speed * move_direction, _get_h_weight())
#	if move_direction !=0:                    
#		$Body.scale.x = move_direction   ###line 89/90 not needed?###

func _get_h_weight():
	return 0.2 if is_grounded else 0.1

func jump():
	velocity.y = max_jump_velocity
	is_jumping = true

func _check_is_grounded(raycasts = self.raycasts):
	for raycast in raycasts.get_children():
		if raycast.is_colliding():
			return true
	
	#if loop completes then raycast was not detected
	return false

func _on_Area2D_body_exited(_body):
	set_collision_mask_bit(DROP_THRU_BIT, true)
	standing_collision.call_deferred("set_disabled", false)

func damage(amount):
	if invulnerability_timer.is_stopped():
		invulnerability_timer.start()
		_set_health(health - amount)
		effects_animation.play("damage")
		effects_animation.queue("flash")

func connect_camera(camera):
	var camera_path = camera.get_path() 
	remoteTransform2D.remote_path = camera_path

func kill():
	yield(get_tree().create_timer(0.5), "timeout")
	queue_free()
	Globals.emit_signal("player_died")

func refill_health():
	print("health refilled")
	_set_health(max_health)

func _set_health(value): 
	var prev_health = health
	health = clamp(value, 0, max_health)
	if health != prev_health:
		emit_signal("health_updated", health) 
		if health == 0:
			kill()
			emit_signal("killed")

func _on_InvulnerabilityTimer_timeout(): 
	effects_animation.play("rest")

func _check_bounce(delta):
	if velocity.y > 0:
		for raycast in bounce_raycasts.get_children():
			raycast.cast_to = Vector2.DOWN * velocity * delta + Vector2.DOWN
			raycast.force_raycast_update()
			if raycast.get_collider() is SpringArea:
				velocity.y = (raycast.get_collision_point() - raycast.global_position - Vector2.DOWN).y / delta
				raycast.get_collider().entity.call_deferred("be_bounced_upon", self)
				break

func bounce(bounce_velocity = BOUNCE_VELOCITY):
	velocity.y = bounce_velocity
