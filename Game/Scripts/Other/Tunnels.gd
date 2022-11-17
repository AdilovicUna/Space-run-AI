extends Spatial

onready var game = get_parent()
onready var hans = get_node_or_null("../Hans")
onready var battery = get_node_or_null("../UI/Battery")

# load traps
var scenes = { "trap_scenes" : [],
                "bug_scenes" : [],
                "virus_scenes" : [],
                "token_scenes" : []
                }
var rand = RandomNumberGenerator.new()
var obstacle_number = 0

const DEVIATION = 0.01
const ROTATE_SPEED = 2
const TRAP_RANGE_FROM = 90
const TRAP_RANGE_TO = 110

# IMPORTANT!
# agent's function move returns a list of 2 elements:
# - first element indicates the movement : -1 - left, 0 - just go forward, 1 - right
# - second element decides if Hans should shoot : 1 - yes, 0 - no

func _physics_process(delta):
    if game.done:
        return
        
    var move = game.agent.move(game.state.get_state(), game.score.get_score())
    #rotates all children of "traps"
    if move[0] == 1:
        var tunnel = get_child(hans.get_current_tunnel())
        tunnel.rotate_object_local(Vector3.RIGHT,-ROTATE_SPEED * delta)
    elif move[0] == -1:
        var tunnel = get_child(hans.get_current_tunnel())
        tunnel.rotate_object_local(Vector3.LEFT,-ROTATE_SPEED * delta)
    if not hans == null: # if it is not instanced we can't call the function       
        hans.switch_animation(move[1] == 1)

func create_first_level_traps(tunnel):
    if game.self_playing_agent:
        rand.seed = game.seed_val
    else:
        rand.randomize()
        
    # get the level we are making traps for
    var level = tunnel
    # pick number of traps to be added
    var num_of_traps = rand.randi_range(50,65)
    var x = 1200
    for n in num_of_traps:
        # add space between traps
        x -= rand.randi_range(TRAP_RANGE_FROM,TRAP_RANGE_TO)
        # check if the trap will be inside the tunnel
        # if not, break
        if x < -1200:
            break
        create_one_obstacle(level, x) 

func create_one_obstacle(level,x):
    # pick which kind of obstacle will be added
    var scene  = pick_scene(level)   
    
    # get the level we are making traps for
    var tunnel = get_child(level)
    
    # pick an obstacle
    var i = pick_obstacle(scene)
    
    # make an instance
    var obstacle = scene[i].instance()
    obstacle.translation.x = x
    
    # hide all csg shapes when the window isn't visible
    if not VisualServer.render_loop_enabled:
        game.hide_csg_shapes(obstacle)
        
    tunnel.add_child(obstacle)
    rotate_obstacle(obstacle)

func pick_obstacle(scene):
    if scene == scenes["token_scenes"]:
        return 0
    elif scene == scenes["virus_scenes"]:
        # rotavirus (index 0 in virus_scenes) will occur 75% of the time
        var i = rand.randf_range(0,1)
        return 0 if i <= 0.75 else 1
    else:
        return rand.randi_range(0, len(scene) - 1)

func pick_scene(level):
    # NOTE: we are guaranteed to have at least one of the 4 scenes non empty
    
    var scene = scenes["trap_scenes"]
    
    # only if token scenes are enabeled
    if (scenes["token_scenes"].size() > 0 and (rand.randf_range(0,1) < 0.1 or obstacle_number >= 10) or 
        (scenes["trap_scenes"].size() == 0 and scenes["bug_scenes"].size() == 0 and scenes["virus_scenes"].size() == 0)):
        obstacle_number = 0
        return scenes["token_scenes"]
        
    var r = rand.randi_range(0,1)
    
    # firstly we try to find default scene element for that tunnel
    if scenes["bug_scenes"].size() > 0 and level == hans.lvl.TWO and (r == 0  or scene == []):
        scene = scenes["bug_scenes"]
    elif scenes["virus_scenes"].size() > 0 and level == hans.lvl.THREE and (r == 0 or scene == []):
        scene = scenes["virus_scenes"]
    obstacle_number += 1
        
    # if all elements that would usually be in that tunnel aren't enabeled, then we pick randomly out of remaining ones
    while scene.size() == 0:
        var s = scenes.keys()
        scene = scenes[s[rand.randf_range(0, s.size()-1)]]
    
    return scene
 
func rotate_obstacle(obstacle):
    # rotate the obstacle under some angle
    var angle = rand.randi_range(0,5) * (PI / 3)
    obstacle.rotate_x(angle)
          
func delete_obstacle_until_x(level,x):
    var tunnel = get_child(level)
    for obstacle in tunnel.get_children():
        if not "light" in obstacle.name and not "torus" in obstacle.name and not "Bullet" in obstacle.name:
            if obstacle.translation.x > x:
                obstacle.queue_free()
            else:
                return

func bug_virus_movement(delta, curr_tunnel):
    var tunnels = get_children()
    for obstacle in tunnels[curr_tunnel].get_children():
        # we only move bugs / viruses
        if not isBugOrVirus(obstacle.name):
            continue;
        
        # obstacles start moving torwards Hans only when he gets close enough
        # thit way we can avoid them all alligning at one point
        if obstacle.get_global_transform().origin.x < hans.get_global_transform().origin.x - (150):
            continue;
            
        var tunnel_rot = tunnels[curr_tunnel].rotation.x + PI
        var obstacle_rot = obstacle.rotation.x + PI
        
        if (-1) * DEVIATION > tunnel_rot + obstacle_rot  or tunnel_rot + obstacle_rot > DEVIATION:
            var dec = fmod(abs(obstacle_rot + tunnel_rot),2 * PI) 
            var inc = abs(2 * PI - fmod(tunnel_rot + obstacle_rot, 2* PI))
            # speed for every instance is generated randomly
            # so obstacles of the same species will do not necessarily have the same speed
            if dec > inc:
                obstacle.rotate_x(obstacle.speed * delta * 75)
            else:
                obstacle.rotate_x(-obstacle.speed * delta * 75)      

func isBugOrVirus(name):
    for bug in game.bugs:
        if bug in name:
            return true
    for virus in game.viruses:
        if virus in name:
            return true
    return false
