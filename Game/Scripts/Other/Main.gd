extends Node


var options = """
argument options:
    - n=int : number of games
    - agent=string : name of the agent [Keyboard, Static, Random, MonteCarlo]
    - tunnel=int : number of the tunnel to start from [1, 2, 3]
    - env=[string] : list of obstacles that will be chosen in the game 
        (subset of) [traps, bugs, viruses, tokens, I, O, MovingI, X, Walls, Hex, HexO, Balls, Triangles, HalfHex]
    - shooting=bool : enable or disable shooting [enabled, disabled]
    - dists=int : number of states in a 100-meter interval
    - rots=int : number of states in 360 degrees rotation
    - options : displays options
"""

var game_scene = preload("res://Scenes/Other/Game.tscn")
var game

var all_agents = ["Keyboard", "Static", "Random", "MonteCarlo"]
var all_env = ["traps", "bugs", "viruses", "tokens", "I", "O", "MovingI", "X", "Walls", "Hex", "HexO", "Balls", "Triangles", "HalfHex"]

# all parameters and their default values
var n = 100
var agent = "Keyboard"
var tunnel = 1
var env = []
var shooting = true
var actions = [[-1,0], [0,0], [1,0], [-1,1], [0,1], [1,1]] # depend on shooting parameter
var dists = 1
var rots = 1

var agent_inst = Keyboard.new()

var scores_sum = 0.0
var scores_count = 0

var paramSet = false

var start
var end
var num_of_ticks = 0.0

func _ready():
    # get args
    var unparsed_args = OS.get_cmdline_args()
    
    # show options
    if unparsed_args.size() == 1 and unparsed_args[0] == "--options":
        display_options()
    
    # parse agrs
    var args = {}
    for arg in unparsed_args:
        if arg.find("=") > 0:
            var key_value = arg.split("=")
            args[key_value[0].lstrip("--")] = key_value[1]
    
    # set param, if something went wrong, show options
    if set_param(args) == false:
        display_options()
    else:
        start = OS.get_ticks_usec()
        instance_agent()
        agent_inst.init(actions)                
        play_game()

func play_game():     
    if agent == "Keyboard" and VisualServer.render_loop_enabled: # play a regular game
        game = game_scene.instance()
        set_param_in_game()
        add_child(game)
    elif n > 0:
        n -= 1
        game = game_scene.instance()
        set_param_in_game()
        agent_inst.start_game()
        game.connect("game_finished", self, "on_game_finished")
        add_child(game)
    else:
        end = OS.get_ticks_usec()
        agent_inst.save()
        print_avg_score()
        get_tree().quit()        

func set_param_in_game():
    game.set_agent(agent, agent_inst)
    game.set_tunnel(tunnel)
    game.set_env(env)
    game.set_dists(dists)
    game.set_rots(rots)
    game.set_seed_val()

func instance_agent():
    # if there is no window, static agent is default
    if not VisualServer.render_loop_enabled:
        agent_inst = Static.new()
        
    match agent:        
        "Static":
            agent_inst = Static.new()
        "Random":
            agent_inst = Random.new()
        "MonteCarlo":
            agent_inst = MonteCarlo.new()


func display_options():
    get_tree().quit() 
    print(options)

func set_param(param):
    if not paramSet:
        paramSet = true
        # modify options based on args
        for key in param:
            match key:
                "n":
                    n = int(param[key])
                "agent":
                    agent = param[key]
                "tunnel":
                    tunnel = int(param[key])
                "env":
                    env = param[key].split(",")
                "shooting":
                    match param[key]:
                        "enabled" :
                            shooting = true
                        "disabled" :
                            shooting = false
                        _:
                            return false
                "dists":
                    dists = int(param[key])
                "rots":
                    rots = int(param[key])
                        
        #check if everything is valid
        if (n < 0 or not agent in all_agents or 
            tunnel < 0 or tunnel > 3 or not check_env() or
            dists < 0 or rots < 0):
            return false   
    
    # we don't need actions that have shooting if it was specified in the command line
    # or it is not necessary (there is nothing in the env to shoot)
    
    if not shooting or (not env.empty() and not "bugs" in env and not "viruses" in env):
        actions = actions.slice(0,2)
        
    return true
        
func check_env():
    for elem in env:
        if not elem in all_env:
            return false
    return true

func add_score(score):
    scores_count += 1
    scores_sum += score

func print_score(score):
    print("Game %d score: %.1f" % [scores_count,score])   

func print_avg_score():
    print("Average score: %.1f" % [scores_sum / scores_count])
    
    # Note: we have to turn the microseconds to seconds, thus we devide by 1_000_000
    print("Average time per tick: ", (end - start)/(num_of_ticks * 1_000_000))
        
func on_game_finished(score, ticks):
    # calculations
    num_of_ticks += ticks
    add_score(score)
    # finish up
    print_score(score)
    agent_inst.end_game(score)        
    # start a new game
    play_game()
    
