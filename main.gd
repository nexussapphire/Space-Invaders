extends Node2D

const row_len = 8
const rows = 5
const wall_reset = 2
const start_time = 3
const invader_scene_len = row_len * rows

@export_category("invaders")
@export var invader1_scene : PackedScene
@export var invader2_scene : PackedScene
@export var invader3_scene : PackedScene
@export var invader_bonus_scene : PackedScene
@export_category("doot noises")
@export var doot1 : AudioStreamWAV
@export var doot2 : AudioStreamWAV
@export var doot3 : AudioStreamWAV
@export var doot4 : AudioStreamWAV

var doot = 4
var saucer_speed = .001
var disabled_invaders = 0
var move_counter = row_len * rows
var wall_reset_counter = 2
var level = 1
var lives = 3
var score = 0
var moving_right = true
var wall_hit = false
var game_running = false
var paused = false
var flyby = true

signal game_start
signal game_soft_reset
signal game_resume


#Primaraly pause state, easier because its tied to one key.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if not paused:
			freeze_state()
			paused = true
			$CanvasLayer/CenterLabel.text = "PAUSED"
			$CanvasLayer/CenterLabel.visible = true
			$CanvasLayer/CenterButton.text = "FULL SCREEN"
			$CanvasLayer/CenterButton.show()
			if not $StartTimer.is_stopped():
				$StartTimer.set_paused(true)
		elif paused and not game_running:
			if $StartTimer.is_paused():
				$StartTimer.set_paused(false)
				$CanvasLayer/CenterButton.visible = false
				paused = false
				$CanvasLayer/CenterLabel.text = "LEVEL %s" % level
			else:
				game_resume.emit()
				game_running = true
				paused = false
				saucer_on_screen()
				get_tree().call_group("Invaders", "stop_animate")
				$CanvasLayer/CenterLabel.visible = false
				$CanvasLayer/CenterButton.visible = false
	#if event.is_action_pressed("ui_down"):
		#win_state()
	#if event.is_action_pressed("ui_up"):
		#disabled_invaders = 21


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Path2D/PathFollow2D/saucer.set_scene_id(4)
	for cont in range(invader_scene_len):
		if cont < row_len:
			spawn_invader(1)
		elif cont < 3 * row_len:
			spawn_invader(2)
		else:
			spawn_invader(3)
	update_grid()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if game_running:
		#Saucer listeneing for over 50% invaders disabled.
		if flyby:
			if disabled_invaders > 0:
				if float(disabled_invaders) / float(invader_scene_len) > .5:
					var path_follow = $Path2D/PathFollow2D
					path_follow.progress_ratio = move_toward(path_follow.progress_ratio, 1, saucer_speed)
					if path_follow.progress_ratio >= 1:
						flyby = false
						path_follow.progress_ratio = 0
					saucer_on_screen()

			
		update_move()
		shoot_at_player()
		$CanvasLayer/Score.text = str(score * 10)
		if disabled_invaders >= invader_scene_len:
			win_state()
			
# "State machine" close enough anyway.
func win_state():
	level += 1
	game_running = false
	update_grid()
		
		
func lose_state():
	$CanvasLayer/CenterLabel.text = "GAME OVER"
	$CanvasLayer/CenterButton.visible = true
	$CanvasLayer/CenterButton.text = "Restart"
	$CanvasLayer/CenterLabel.visible = true
	for life in $Lives.get_children():
		life.show()
	freeze_state()

	
	
func freeze_state():
	game_running = false
	get_tree().call_group("Invaders","animate")
	get_tree().call_group("Missiles","free_all")
	saucer_on_screen(true)
	game_soft_reset.emit()

#Origionaly written to spawn bonus but doesn't now.
func spawn_invader(type : int):
	var invader_type : Node
	match type:
		1:
			invader_type = invader1_scene.instantiate()
		2:
			invader_type = invader2_scene.instantiate()
		3:
			invader_type = invader3_scene.instantiate()
			
	$InvaderScenes.add_child(invader_type)
	invader_type.set_scene_id(type)
	invader_type.wall_hit.connect(_on_invader_hit_wall)
	invader_type.enemy1_hit.connect(_on_enemy1_hit)
	invader_type.enemy2_hit.connect(_on_enemy2_hit)
	invader_type.enemy3_hit.connect(_on_enemy3_hit)
	invader_type.landed.connect(_on_landed)
	
	
##Update_grid handles soft resets, the grid is the centeral part of that.
func update_grid():
	game_soft_reset.emit()
	disabled_invaders = 0
	$CanvasLayer/CenterLabel.text = "LEVEL %s" % level
	$CanvasLayer/CenterLabel.visible = true
	$InvaderBlock.global_position = Vector2(473,108)
	for row in range(rows):
		for point in range(row_len):
			update_invader(row, point, false)
						
	get_tree().call_group("Invaders", "reset_state")
	$Path2D/PathFollow2D.progress = 0
	flyby = true
	saucer_on_screen()
	$StartTimer.start(start_time)

## Moves only one invader. If check_state is true invader needs to be active.
func update_invader(row:int, point:int, check_state = true):
	var pos = $InvaderBlock.get_child(row).get_child(point).get_global_position()
	var offset = row * row_len
	var invader = $InvaderScenes.get_child(offset + point)
	if invader.disabled and check_state:
		return false
		
	$InvaderScenes.get_child(offset + point).target_pos = pos
	$InvaderScenes.get_child(offset + point).frame_animate()
	return true
	
## Handles all of the dificulty and ignores disabled invaders
func shoot_at_player():
	const dificulty = 150
	if randi() % dificulty < level:
		while true:
			if disabled_invaders >= invader_scene_len:
				break
			var selected = $InvaderScenes.get_child(randi() % invader_scene_len)
			if not selected.disabled:
				selected.fire_missile()
				break
				

	
"""This moves one invader every frame allowing the game to have it's trademark
dificulty curve. It speeds up by skipping disabled invaders until it hits an active invader.
It also handles doot state(the stairstep tone) and state with hitting the edge of the screen."""
func update_move() -> void:
	var moved = false
	while not moved:
		if move_counter < invader_scene_len:
			@warning_ignore("integer_division")
			var row = rows - 1 - int(move_counter/row_len)
			var col
			if moving_right:
				if wall_hit:
					col = move_counter % row_len
				else:
					col = row_len - 1 - move_counter % row_len
			else:
				if wall_hit:
					col = row_len - 1 - move_counter % row_len
				else:
					col = move_counter % row_len
				
			# returns a bool resulting in disabled being skipped
			moved = update_invader(row, col)
			move_counter += 1
		else:
			const grid_move = 15
			moved = true
			move_counter = 0
			make_doots()
			if wall_hit:
				$InvaderBlock.position.y = $InvaderBlock.position.y + grid_move
				wall_hit = false
			elif moving_right:
				$InvaderBlock.position.x = $InvaderBlock.position.x + grid_move
			else:
				$InvaderBlock.position.x = $InvaderBlock.position.x - grid_move
				
			if not $InvaderScenes.get_child(0).wall_signal:
				if wall_reset_counter > 0:
					wall_reset_counter -= 1
				else:
					wall_reset_counter = wall_reset
					get_tree().call_group("Invaders", "wall_hit_reset")
					
					
func make_doots():
	if doot > 3:
		doot = 0
	match doot:
		0:
			$AudioStreamPlayer.set_stream(doot1)
		1:
			$AudioStreamPlayer.set_stream(doot2)
		2:
			$AudioStreamPlayer.set_stream(doot3)
		3:
			$AudioStreamPlayer.set_stream(doot4)
			
	$AudioStreamPlayer.play()
	doot += 1
				

## sets animation and sound of saucer.
func saucer_on_screen(stop = false):
	var saucer = $Path2D/PathFollow2D/saucer
	var audio = saucer.get_node("AudioStreamPlayer2D")
	var visual = saucer.get_node("AnimatedSprite2D")
	if stop or paused:
		audio.stop()
	elif  $Path2D/PathFollow2D.progress_ratio == 0 or $Path2D/PathFollow2D.progress_ratio == 1:
		audio.stop()
		visual.set_animation("Flying")
		visual.stop()
	else:
		if not audio.is_playing() and not paused:
			audio.play()
		if not visual.is_playing():
			visual.play("Flying")
		
		
# Signals that are attached when spawned.
func _on_invader_hit_wall():
	moving_right = not moving_right
	wall_hit = true


func _on_start_timer_timeout() -> void:
	$CanvasLayer/CenterLabel.visible = false
	game_start.emit()
	get_tree().call_group("Invaders","stop_animate")
	game_running = true
	
	
func _on_enemy1_hit():
	disabled_invaders += 1
	score +=3
	
	
func _on_enemy2_hit():
	disabled_invaders += 1
	score +=2
	
	
func _on_enemy3_hit():
	disabled_invaders += 1
	score +=1
	

func _on_landed():
	lose_state()
	


func _on_tank_tank_hit() -> void:
	if lives > 0:
		freeze_state()
		$StartTimer.start(start_time)
		lives -= 1
		$Lives.get_child(lives).visible = false
	else:
		lose_state()


func _on_center_button_pressed() -> void:
	if paused:
		if DisplayServer.window_get_mode() != DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		level = 1
		lives = 3
		score = 0
		$CanvasLayer/CenterButton.hide()
		update_grid()


func _on_saucer_enemy_bonus_hit() -> void:
	score += randi_range(4,9)
	$Path2D/PathFollow2D.progress_ratio = 0
	flyby = false
	saucer_on_screen()
