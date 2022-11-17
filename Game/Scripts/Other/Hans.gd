extends KinematicBody

export(PackedScene) var BulletZero
export(PackedScene) var BulletOne

const MAX_BULLETS_PER_BUTTON_PRESS = 8
const SPEED_INCREASE = 5.0

enum lvl {ONE, TWO, THREE}

onready var game = get_parent()
onready var ground = get_node("../Ground")
onready var tunnels = get_node("../Tunnels") # Tunnels
onready var tunnels_children = get_node("../Tunnels").get_children() # lvl1, lvl2, lvl3
onready var score = get_node("../UI/Score")
onready var end = get_node("../UI/End")
onready var level = get_node("../UI/Level")
onready var battery = get_node("../UI/Battery")
onready var sick = get_node("../UI/Sick")
onready var state = get_node("../UI/State")

var rand = RandomNumberGenerator.new()

var next_tunnel = lvl.TWO
var curr_tunnel = lvl.ONE

var speed = 35.0
var next_trap_pos = rand.randi_range(1120,1190) # first trap for the next level will be here
var new_trap = 3650 # start producing traps for the next level at this point
var show_level = 0 # used to measure how long level lable should be displayed
var isShootingButtonPressed = false # indicates whether Hans should shoot
var can_shoot = true
var bullets_in_air = 0
var energy_token_exists = false
var next_trap_posX = 0.0
var next_trap_rotX = 0.0

func _physics_process(delta):
    # the game just started
    if show_level == 0:
        show_level_label()
        
    # we passed one tunnel
    if translation.x < (tunnels_children[curr_tunnel].translation.x - 1250): 
        update_curr_tunnel()
    
    # Hans entered the new tunnel, hide the level label
    if level.visible and abs(translation.x - show_level) > 75:
        level.hide()        
        
    tunnels.delete_obstacle_until_x(curr_tunnel,translation.x - tunnels_children[curr_tunnel].translation.x + 50)
    
    # create a trap in the next tunnel every 50 meters
    if translation.x < new_trap:
        create_new_trap()
    
    # updating score 
    score._on_Meter_Passed()
    
    # Hans's movement
    var velocity = Vector3.LEFT * speed
    velocity = move_and_slide(velocity)
    
    check_collisions()
    
    # bugs and viruses need to move torwards Hans
    # but not in the first tunnel    
    tunnels.bug_virus_movement(delta, curr_tunnel)
    
    if isShootingButtonPressed:
        shoot()
        
    game.num_of_ticks += 1
    
    # type needs to be calculated before 
    # so we know where the next trap is on x axis
    var type = calc_type()
    state.update_state(calc_dist(),calc_rot(),type)

func set_tunnel_vars(starting_level, tunnel):
    next_tunnel = (tunnel + 1) % tunnels.get_child_count()
    curr_tunnel = tunnel
    var other1_tunnel  = (curr_tunnel + 1) % tunnels.get_child_count()
    var other2_tunnel = (curr_tunnel + 2) % tunnels.get_child_count()
    tunnels_children[other1_tunnel].translation.x = tunnels_children[curr_tunnel].translation.x - 2500
    tunnels_children[other2_tunnel].translation.x = tunnels_children[curr_tunnel].translation.x - 5000
    level.set_level(starting_level)
    
func set_speed(n):
    # n represents how many times we need to increase the speed
    # based on which tunnel we are in
    speed += n * SPEED_INCREASE
    
func calc_dist():
    # this will give us a number until the next trap
    var real_dist = int(translation.x - tunnels_children[curr_tunnel].translation.x - next_trap_posX)
 
    # we determine which state we are in
    # eg. game.dists = 4, 100/4 = 25 
    # (we need to round up torwards the ceiling 
    # or otherwise we will have an extra state 
    # for the numbers not divisible by 100)
    # possible dists are >0, >25, >50, >75
    # suppose real_dist is 60, our state should be >50
    # 60 div 25 = 2, 25 * 2 = 50
    var interval = int(ceil(100.0 / game.dists))
    var result = interval * (real_dist / interval)
    
    if result < 0 or result > 99:
        result = interval * (game.dists - 1)
        
    return result

func calc_rot():
    # get the actual rotation
    # note: rotation_degrees returns a number [-180,180]

    var real_rot = int(next_trap_rotX + 
                tunnels_children[curr_tunnel].rotation_degrees.x) % 360
                
    if real_rot < 0:
        real_rot += 360

    # similar to calc_dist()cd De   
    var interval = int(ceil(360.0 / game.rots))
    return abs(interval * (real_rot / interval) - 360)
    
func calc_type():
    # find out what is the next trap 
    var pos = translation.x - tunnels_children[curr_tunnel].translation.x
    var type
    var found = false
    
    for obstacle in tunnels_children[curr_tunnel].get_children():
        if (not "light" in obstacle.name and not "torus" in obstacle.name and 
            not "Bullet" in obstacle.name):
            if obstacle.translation.x <= pos:
                found = true
                type = obstacle.name
                next_trap_posX = obstacle.translation.x
                next_trap_rotX = obstacle.rotation_degrees.x
                break
       
    if !found:
        for obstacle in tunnels_children[next_tunnel].get_children():
            if (not "light" in obstacle.name and not "torus" in obstacle.name and 
                not "Bullet" in obstacle.name):
                    type = obstacle.name
                    next_trap_posX = obstacle.translation.x
                    next_trap_rotX = obstacle.rotation_degrees.x
                    break
                    
    # clean up the string we got
    if '@' in type:
        type = type.substr(type.find('@'),type.find_last('@')).replace('@','')
    if "Trap" in type:
        return type.trim_prefix("Trap")

    return game.short_names[type]

func check_collisions():
    for index in get_slide_count():
        var collision = get_slide_collision(index)
             
        if collision.collider is KinematicBody:
            # increase battery in Hans picks up an energy token
            if "Token" in collision.collider.name:
                if not game.self_playing_agent:
                    $Sounds/pickUpTokenSound.play()
                battery.value = 100
            # decrease battery if Hans touches a bug
            elif "Worm" in collision.collider.name or  "Ladybug" in collision.collider.name:
                if not game.self_playing_agent:
                    $Sounds/bugSqishSound.play()
                battery.value -= 25
            # make Hans sick if he touches rotavirus
            elif "Rotavirus" in collision.collider.name and not sick.visible:
                if not game.self_playing_agent:
                    $Sounds/coughingSound.play()
                sick.show()
                $Sick_timer.start()
            # End game if Hans touches the trap or bacteriophage virus  
            # or a trap
            # or rotavirus while he is sick                                           
            else:	
                game._game_over()
                return   
            collision.collider.queue_free()
            return

func create_new_trap():
    new_trap -= 50
    if next_trap_pos > -1200:
        tunnels.create_one_obstacle(next_tunnel,next_trap_pos)
        
    # choose a place for the next obstacle
    next_trap_pos -= rand.randi_range(tunnels.TRAP_RANGE_FROM,tunnels.TRAP_RANGE_TO)

func update_curr_tunnel():
    var prev_tunnel = curr_tunnel
    # update cur_tunnel Hans is running through
    next_tunnel = (next_tunnel + 1) % tunnels_children.size()
    curr_tunnel = (curr_tunnel + 1) % tunnels_children.size()
    
    show_level_label()
    if game.self_playing_agent and  level.get_level() > game.max_tunnels:
        game._game_over()        
    
    # increase speed after a full lap
    if(curr_tunnel == lvl.ONE):
        speed += SPEED_INCREASE
        battery.update_timer()
        
    if game.self_playing_agent:
        rand.seed = game.seed_val
    else:
        rand.randomize()
    
    # restart next_trap_pos
    next_trap_pos = rand.randi_range(1120,1190)
    
    translate_tunnel_and_ground(prev_tunnel)    
    
    
func show_level_label():
    #show which level we are approaching
    show_level = translation.x
    level.update_level()
    level.show()
    

func translate_tunnel_and_ground(prev_tunnel):
    # making tunnels (and ground) infinite by moving them forward
    # after Hans passes them	
    tunnels_children[prev_tunnel].translation.x -= 7500    # move tunnel ahead (3x2500)
    if translation.x < ground.translation.x - 2000:
        ground.translation.x -= 3000 # move ground ahead

func get_current_tunnel():
    return curr_tunnel
  
func switch_animation(move):
    # toggle between Hans shooting and just running
    if move:
        isShootingButtonPressed = true
        get_node("Pivot/Hans/Movement").play("HansShooting")
    else:
        isShootingButtonPressed = false
        bullets_in_air = 0        
        get_node("Pivot/Hans/Movement").play("HansRunning") 

func shoot():
    if bullets_in_air < MAX_BULLETS_PER_BUTTON_PRESS and can_shoot:
        
        # play shooting sound
        if not game.self_playing_agent:
            $Sounds/shootSound.play()
        
        # create bullet instance
        var new_bullet = null
        
        if rand.randi_range(0,1) == 0:
            new_bullet = BulletZero.instance()
        else:
            new_bullet = BulletOne.instance()
            
        # hide all csg shapes when the window isn't visible
        if not VisualServer.render_loop_enabled:
            game.hide_csg_shapes(new_bullet)
            
        tunnels_children[curr_tunnel].add_child(new_bullet)
        new_bullet.global_transform = $Pivot/Hans/Muzzle.global_transform
        
        bullets_in_air += 1
        can_shoot = false
        
        # Hans loses 1% battery for every bullet
        battery.decrease_value()
        
        $Shooting_timer.start()        


func _on_shooting_timer_timeout():
    can_shoot = true


func _on_Sick_timer_timeout():
    sick.hide()

