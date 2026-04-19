extends CharacterBody2D

var damage = 10

@export var speed: int = 300
@export var acceleration: int = 20
@export var jump_speed: int = 500

@onready var hit_box: Area2D = $HitBox
@onready var animations: AnimatedSprite2D = $Anim/AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var slide_timer: Timer = $SlideTimer
@onready var slide_area_2d_left: Area2D = $SlideArea2DLeft
@onready var slide_area_2d_right: Area2D = $SlideArea2DRight

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

enum State{IDLE, RUN, JUMP, FALL, SLIDE, POUND}
var current_state: State = State.IDLE

func _physics_process(delta: float) -> void:
	handle_input(delta)
	handle_hitbox()
	update_movement(delta)
	update_states()
	update_animation()
	if not dead:
		move_and_slide()

@export var health:int = 100
var can_take_damage: bool = true
var dead: bool
func handle_hitbox():
	var hitbox_areas = hit_box.get_overlapping_areas()
	var damage: int
	if hitbox_areas:
		var hitbox = hitbox_areas.front()
		if hitbox.get_parent().is_in_group("mob"):
			print(hitbox.get_parent())
			damage = hitbox.get_parent().damage_to_deal
	if can_take_damage:
		take_damage(damage)

func take_damage(damage):
	if damage != 0:
		if health > 0:
			health -= damage
			print("player health: ", health)
			if health <= 0:
				health = 0
				dead = true
				handle_death()
			take_damage_cooldown(1.0)

func handle_death():
	$GPUParticles2D.emitting = true
	$Anim.visible = false
	await get_tree().create_timer(1.5).timeout
	self.queue_free()

func take_damage_cooldown(wait_time):
	can_take_damage = false
	await get_tree().create_timer(wait_time).timeout
	can_take_damage = true

func handle_input(delta: float) -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		slide_timer.stop()
		velocity.y = -jump_speed
		current_state = State.JUMP
	
	var direction = Input.get_axis("left", "right")
	
	if not is_on_floor():
		if Input.is_action_just_pressed("pound"):
			set_damage("heavy")
			current_state = State.POUND
		else:
			if direction != 0:
				velocity.x = move_toward(velocity.x, speed * direction, acceleration)
			else:
				velocity.x = lerp(velocity.x,0.0,delta)
	else:
		if slide_timer.is_stopped():
			if direction != 0:
				if Input.is_action_just_pressed("slide") and not current_state == State.SLIDE:
					current_state = State.SLIDE
					set_damage("normal")
					slide_timer.start()
				else:
					velocity.x = move_toward(velocity.x, speed * direction, acceleration)
			else:
				velocity.x = move_toward(velocity.x, 0, acceleration)
		else:
			if velocity.x > 0:
				slide_area_2d_right.get_child(0).disabled = false
				$SlideArea2DLeft/Sprite2D.visible = true
				velocity.x += 10
			else:
				slide_area_2d_left.get_child(0).disabled = false
				$SlideArea2DRight/Sprite2D.visible = true
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
			slide_area_2d_right.get_child(0).disabled = true
			slide_area_2d_left.get_child(0).disabled = true
			$SlideArea2DRight/Sprite2D.visible = false
			$SlideArea2DLeft/Sprite2D.visible = false
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
	$SlideArea2DRight/Sprite2D.visible = true
	$SlideArea2DLeft/Sprite2D.visible = true
	animation_player.play("ground_pound")


func update_animation() -> void:
	if velocity.x != 0:
		animations.scale.x = sign(velocity.x)
	
	match current_state:
		State.IDLE: animations.play("idle")
		State.RUN: animations.play("run")
		State.JUMP: animations.play("jump")
		State.FALL: animations.play("recep")
		State.SLIDE: animations.play("slide")
		State.POUND: animations.play("pound")

func set_damage(attack_type):
	var current_damage_to_deal: int
	if attack_type == "normal":
		current_damage_to_deal = 10
	elif attack_type == "heavy":
		current_damage_to_deal = 20
	damage = current_damage_to_deal


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "ground_pound":
		$SlideArea2DRight/Sprite2D.visible = false
		$SlideArea2DLeft/Sprite2D.visible = false
