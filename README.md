# Space Invaders
#### Video Demo: <https://youtu.be/iYFGuioaVrQ>
#### Description: A somewhat faithful clone of space invaders built with GDScript on the Godot engine. All assets and sound was made by yours truly!

## Main script
The main script handles the brunt of the work. It handles state, moving the grid, the pause menu, and ui elements, and the doot noises.

### Nodes vs code
Godot's documentation covers the importants of using the built in tools as much as possible but I did end up writing a lot of code. It's basically a result of compiled code vs an interpreted language.

### The grid
The grid was the primary focus of this script. The movement is handled every frame to mimic the characteristics of the original game.

I moved a box of points after all the invaders were updated. The invaders got updated one at a time every frame refresh as a result the screen kinda looks like its tearing. The invaders also update their animation when they are moved like the old game.

I could have just put the invaders in a grid and move the whole grid. This is usually the way most people go but it takes away from the charm.

There's also the speed of the invaders which are handled by the movement instead of a counter that ramps up speed. 

### State Machine
I handled the state in the main thread because It's where the brunt of the work is done. It's also logical due to everything spawning off of the main scene.

I originally planed on six states but settled on five.
- win
- lose
- soft-reset
- hard-reset
- pause -freeze_state
- resume

Hard reset was supposed to be used for the start menu but didn't make the cut. Every other state made it and largely does what you might expect. As a result of reset grid being so useful, it kinda just became the soft reset state.

I only made signals when it impacted the state of other scenes or where signals were possible.

### Invaders attack
It would be a very boring game if the invaders just never attacked, that last guy is pretty tough to get. If it's any surprise, the attack pattern is purely random.

```GDScript
func shoot_at_player():
	const dificulty = 150
	if randi() % dificulty < level:
```
This is responsible for how hard the game gets. Basically as the difficulty goes up the more invaders that will randomly shoot at you. This also checks for disabled invaders.

The theory randomly choosing an active invader is based in tactic. If you narrow the invader block it takes longer for them to get down but their fire is more focused. If you just pick them off and don't worry about the sides their fire is less focused but they move down faster.

They fire about the same amount no matter how many are still active. The level goes up and it allows a bigger percent of them to fire also gdscript treats non zero numbers as true. They're aggressive because the barricades are non-destructible.

### peanuts
#### Paused
The pause menu freezes the state of the game. if the start timer is going, it pauses the timer and avoids breaking anything if resumed. That's where you can full screen.

## Enemy script
### Shared logic
The enemy script is used for all invaders as the only difference is the signal it puts off when hit. The main script handles the grid, points, and state.

### Instantiated at runtime
Signals work from an instantiated scene to the instantiator better than the other way around. At instantiation they have their `scene_id` set. The best solution I came up with is to use groups and global functions. (Godot doesn't document scope very well)

Groups are the solution Godot provides for minimizing coupling as it allows you to call a function for every entity in the group.

### Wall collisions
Invaders stop moving and turn invisible when they are hit. This makes it easy to let individual invaders report if they hit the wall. If they report it calls the group and tells all the others not to report hitting the wall until the main script resets that state, kind of like collision.

```GDScript
if scene_id != 4:
    if target_pos.x < 396 or target_pos.x > 887:
    	if wall_signal and not disabled:
    		wall_hit.emit()
    		get_tree().call_group("Invaders", "wall_hit_transmitted")
```

Wall collisions are based on their expected x coordinates as seen above. Landing on the ground works in a similar fashion. 

### Deactivated
The invader deactivates after the end of the pop animation. This is done as a result of the saucer resetting it's state after signaling it was hit.

## tank
It moves, shoots, and detects collisions.

## Missiles
It moves up, detects collisions, and despawns.
