extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_timer: Timer = $Timer

var is_jumping = false

func _ready():
	animation_timer.wait_time = 0.2
	animation_timer.connect("timeout",_on_animation_timer_timeout,0)
	#print($".".is_on_floor())

func _physics_process(delta):
	var direction = Input.get_axis("ui_left", "ui_right")
	if animation_timer.is_stopped():
		if not is_on_floor():
			velocity.y += gravity * delta

			if velocity.y >= 0:
				if Input.is_action_pressed("ui_down"):
					animated_sprite.play("recep")#anim chute rapide
				else:
					animated_sprite.play("idle")
			else:
				animated_sprite.play("jump")
		else:
			if is_jumping and Input.is_action_pressed("ui_down") :
				is_jumping = false
				animated_sprite.play("recep")
				animation_timer.start()
			elif Input.is_action_pressed("ui_down") and direction:
				animated_sprite.play("slide")
			else:
				if velocity.x == 0:
					animated_sprite.play("idle")
				else:
					animated_sprite.play("run")
			
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			is_jumping = true

		#var direction = Input.get_axis("ui_left", "ui_right")
		if direction:
			velocity.x = direction * SPEED

			if velocity.x > 0:
				animated_sprite.flip_h = true
			elif velocity.x < 0:
				animated_sprite.flip_h = false
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	else:
		if animated_sprite.animation == "recep":
			velocity.x = 0
			animated_sprite.stop()
			is_jumping = false
	
	move_and_slide()
 
func _on_animation_timer_timeout():
	animation_timer.stop()
