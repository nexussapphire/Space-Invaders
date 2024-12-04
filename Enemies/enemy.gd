extends RigidBody2D

signal enemy1_hit
signal enemy2_hit
signal enemy3_hit
signal enemy_bonus_hit
signal wall_hit
signal landed

var scene_id = 1
var wall_signal = true
var disabled = false
@onready var target_pos : Vector2 = position
@onready var sprite = $AnimatedSprite2D
@export var missile_scene : PackedScene

#Initialization
func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 3
	animate()
	
#Physics based object, needs to be controled on the physics frame.
func _integrate_forces(_state: PhysicsDirectBodyState2D) -> void:
	position = target_pos


# Handles wall collisions and ground collision.
func _process(_delta: float) -> void:
	if scene_id != 4:
		if target_pos.x < 396 or target_pos.x > 887:
			if wall_signal and not disabled:
				wall_hit.emit()
				get_tree().call_group("Invaders", "wall_hit_transmitted")
				
		if target_pos.y >= 650:
			landed.emit()
			get_tree().call_group("Invaders", "animate")
		

# collision handling, moving missiles onto main scene etc.
func _on_body_entered(_body: Node) -> void:
	sprite.play("pop")
	var new_parent = get_tree().current_scene.get_node("InvaderMissiles")
	$CollisionShape2D.set_deferred("disabled", true)
	for missile in $Missiles.get_children():
		missile.set_deferred("reparent",new_parent)
	disabled = true

	
	
"""Spawned at runtime so signals are messy. calls functions individually
 or as the invader group"""
func fire_missile():
	if $Missiles.get_child_count() == 0:
		var init = missile_scene.instantiate()
		$Missiles.add_child(init)
		init.is_invader()
		init.global_position = position
		init.rotate(deg_to_rad(180))
		

func wall_hit_transmitted():
	wall_signal = false
	
func wall_hit_reset():
	wall_signal = true
	
func stop_animate():
	animate(false)

func animate(play = true):
	if sprite.is_playing() and sprite.get_animation() == "pop":
		return
	if play:
		sprite.play("Flying")
	else:
		sprite.pause()
	
func frame_animate():
	if sprite.get_animation() == "Flying":
		if sprite.frame == 0:
			sprite.frame = 1
		else:
			sprite.frame = 0
		
func reset_state():
	set_deferred("visible", true)
	disabled = false
	sprite.frame = 0
	$CollisionShape2D.set_deferred("disabled", false)
	animate()


func _on_animated_sprite_2d_animation_finished() -> void:
	if $AnimatedSprite2D.get_animation() == "pop":
		hide()
		match scene_id:
			1:
				enemy1_hit.emit()
			2:
				enemy2_hit.emit()
			3:
				enemy3_hit.emit()
			4:
				enemy_bonus_hit.emit()
			_:
				print("im confused", name)
		
		
func set_scene_id(scene : int):
	scene_id = scene
		
