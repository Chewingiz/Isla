extends CharacterBody2D

class_name Boueu

var is_chasing: bool = true

@export var speed = 20
@export var health = 20
@export var health_max = 80
@export var health_min = 0

var dead: bool = false
var taking_damage: bool = false
var damage_to_deal = 20
var is_dealing_damage: bool = false

var dir: Vector2
const gravity = 900
@export var knockback_force = -200
var is_roaming: bool = true

@onready var player = get_tree().get_nodes_in_group("Player")[0] 
var player_in_area = false

func _process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.x = 0
	move(delta)
	handle_animation()
	move_and_slide()

func move(delta):
	if not dead:
		if not is_chasing:
			velocity += dir * speed * delta
		elif is_chasing and not taking_damage:
			var dir_to_player = position.direction_to(player.position) * speed
			velocity.x = dir_to_player.x
			dir.x = abs(velocity.x) / velocity.x
		is_roaming = true
	elif dead:
		velocity.x = 0

func handle_animation():
	var anim_sprite = $anim/AnimatedSprite2D
	if !dead and !taking_damage and !is_dealing_damage:
		anim_sprite.play("walk")
		if dir.x == -1:
			anim_sprite.flip_h = false
		elif dir.x == 1:
			anim_sprite.flip_h = true
	elif !dead and taking_damage and !is_dealing_damage:
		anim_sprite.play("hurt")
		await  get_tree().create_timer(0.8).timeout
		taking_damage = false
	elif dead and is_roaming:
		is_roaming = false
		handle_death()

func handle_death():
	$AnimationPlayer.play("death")
	$anim.visible = false
	$CollisionShape2D.disabled = true
	$HitBox/CollisionShape2D.disabled = true
	$GPUParticles2D.emitting = true

func _on_direction_timer_timeout() -> void:
	$DirectionTimer.wait_time = choose([1.5,2.0,2.5])
	if not is_chasing:
		dir = choose([Vector2.RIGHT, Vector2.LEFT])
		velocity.x = 0

func choose(array):
	array.shuffle()
	return array.front()


func _on_hit_box_area_entered(area: Area2D) -> void:
	var damage = player.damage
	if area == player.slide_area_2d_left or area == player.slide_area_2d_right:
		take_damage(damage)

func take_damage(damage):
	var knockback_dir = position.direction_to(player.position) * knockback_force
	velocity.x = knockback_dir.x
	health -= damage
	taking_damage = true
	if health <= health_min:
		health = health_min
		dead = true
	

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	self.queue_free()
