extends CharacterBody2D

@export var speed: int = 300
@export var acceleration: int = 20
@export var jump_speed: int = 500

@onready var animations: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var slide_timer: Timer = $SlideTimer
@onready var slide_area_2d_left: Area2D = $SlideArea2DLeft
@onready var slide_area_2d_right: Area2D = $SlideArea2DRight

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

enum State{IDLE, RUN, JUMP, FALL, SLIDE, POUND}
var current_state: State = State.IDLE

func _physics_process(delta: float) -> void:
	handle_input(delta)
	update_movement(delta)
	update_states()
	update_animation()
	move_and_slide()

func handle_input(delta: float) -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		slide_timer.stop()
		velocity.y = -jump_speed
		current_state = State.JUMP
	
	var direction = Input.get_axis("left", "right")
	
	if not is_on_floor():
		if Input.is_action_just_pressed("pound"):
			current_state = State.POUND
		else:
			if direction != 0:
				velocity.x = move_toward(velocity.x, speed * direction, acceleration)
			else:
				velocity.x = lerp(velocity.x,0.0,delta)
	else:
		if slide_timer.is_stopped():
			slide_timer.stop()
			slide_area_2d_right.get_child(0).disabled = true
			slide_area_2d_left.get_child(0).disabled = true
			  
			if direction != 0:
				if Input.is_action_just_pressed("slide") and not current_state == State.SLIDE:
					current_state = State.SLIDE
					slide_timer.start()
				else:
					velocity.x = move_toward(velocity.x, speed * direction, acceleration)
			else:
				velocity.x = move_toward(velocity.x, 0, acceleration)
		else:
			if velocity.x > 0:
				slide_area_2d_right.get_child(0).disabled = false
				velocity.x += 10
			else:
				slide_area_2d_left.get_child(0).disabled = false
				velocity.x -= 10

func update_movement(delta: float) -> void:
	if not is_on_floor():
		if current_state == State.POUND:
			velocity.x = 0
			velocity.y += gravity * delta * 10
		else:
			velocity.y += gravity * delta
	
	if velocity.x > 325:
		velocity.x = 325
	if velocity.x < -325:
		velocity.x = -325

func update_states() -> void:
	match current_state:
		State.IDLE when velocity.x != 0:
			current_state = State.RUN
		
		State.RUN:
			if velocity.x == 0:
				current_state = State.IDLE
			if not is_on_floor() && velocity.y > 0:
				current_state = State.FALL 
		
		State.JUMP when velocity.y > 0:
			current_state = State.FALL
		
		State.FALL when is_on_floor():
			if velocity.x == 0:
				current_state = State.IDLE
			else:
				current_state = State.RUN
		
		State.SLIDE when slide_timer.is_stopped():
			if velocity.x == 0:
				current_state = State.IDLE
			else:
				current_state = State.RUN
		
		State.POUND when is_on_floor():
			ground_pound()
			if velocity.x == 0:
				current_state = State.IDLE
			else:
				current_state = State.RUN

func ground_pound() -> void:
	animation_player.play("ground_pound")


func update_animation() -> void:
	if velocity.x != 0:
		animations.scale.x = -sign(velocity.x)
	
	match current_state:
		State.IDLE: animations.play("idle")
		State.RUN: animations.play("run")
		State.JUMP: animations.play("jump")
		State.FALL: animations.play("recep")
		State.SLIDE: animations.play("slide")
		State.POUND: animations.play("recep")
