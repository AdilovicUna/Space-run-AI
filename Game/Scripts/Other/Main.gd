extends Node

const MAX_LEVEL = 10

var options = """
argument options:
    - n=int :           number of games
    
    - agent=string :    name of the agent
                        options: [Keyboard, Static, Random, MonteCarlo]
                        
    - level=int :       number of the level to start from 
                        options: [1, ... , 10]
                        
    - env=[string] :    list of obstacles that will be chosen in the game 
                        options (any subset of): [traps, bugs, viruses, tokens, I, O, MovingI, X, 
                                                  Walls, Hex, HexO, Balls, Triangles, HalfHex]
                                            
    - shooting=string : enable or disable shooting 
                        options: [enabled, disabled]
                        
    - dists=int :       number of states in a 100-meter interval
    
    - rots=int :        number of states in 360 degrees rotation
    
    - database=string :     read = read the data for this command from an existing file 
                            write = update the data after the command is executed 
                            options: [read, write, read_write]
                            Note: will not influence the following agents: Keyboard, Static, Random
    - agent_specific_param : 
                            indicates parameters specific for the particular agent as follows:
                            Keyboard=[]
                            Static=[]
                            Random=[]
                            Monte Carlo=[float, float] : [GAMMA (range [0,1]), INITIAL OPTIMISTIC VALUE [0,~)]
                        
    - options :         displays options
"""

var game_scene = preload("res://Scenes/Other/Game.tscn")
var game

var all_agents = ["Keyboard", "Static", "Random", "MonteCarlo"]
var all_env = ["traps", "bugs", "viruses", "tokens", "I", "O", "MovingI", "X", "Walls", "Hex", "HexO", "Balls", "Triangles", "HalfHex"]

# all parameters and their default values
var n = 100
var agent = "Keyboard"
var level = 1
var env = []
var shooting = false
var actions = [[-1,0], [0,0], [1,0], [-1,1], [0,1], [1,1]] # depend on shooting parameter
var dists = 1
var rots = 6
var read = false
var write = false
var agent_specific_param = []

var agent_inst = Keyboard.new()

var scores_sum = 0.0
var num_of_games = 0

var paramSet = false

var start
var end
var num_of_ticks = 0.0
var wins = 0
var winning_score = 0.0

var file = File.new()
var command = ""

var seed_val = 0

func _ready():
    # get args
    var unparsed_args = OS.get_cmdline_args()
    # show options
    if unparsed_args.size() == 1 and unparsed_args[0] == "options":
        display_options()
    
    # parse agrs
    var args = {}
    for arg in unparsed_args:
        if arg.find("=") > 0:
            var key_value = arg.split("=")
            args[key_value[0]] = key_value[1]
        
    # set param, if something went wrong, show options
    if set_param(args) == false:
        display_options()
    else:
        start = OS.get_ticks_usec()
        instance_agent()
        build_filename()
        if not agent_inst.init(actions, read, command, n, agent_specific_param):
            print("Something went wrong, please try again")
            print(options)
            get_tree().quit()
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
        agent_inst.save(write)
        print_and_write_ending()
        get_tree().quit()        

func set_param_in_game():
    game.set_agent(agent, agent_inst)
    game.set_tunnel(level - 1) # tunnels start from 0
    game.set_max_tunnels(MAX_LEVEL)
    game.set_env(env)
    game.set_dists(dists)
    game.set_rots(rots)
    game.set_seed_val(seed_val)
    seed_val += 1

func instance_agent():
    # if there is no window, static agent is default
    if agent == "Keyboard" and not VisualServer.render_loop_enabled:
        agent = "Static"
        
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

func build_filename():
    # we sort it so that we would always get the same filename in build_filename()    
    var sorted_env = Array(env)
    sorted_env.sort()
    if sorted_env == []:
        sorted_env = "all"
    
    command = PoolStringArray(["agent=" + String(agent), "level=" + String(level), "env=" + String(sorted_env), 
                            "shooting=" + String(shooting), "dists=" + String(dists), "rots=" + String(rots)]
                                ).join(",").replace(' ','')
   
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
                "level":
                    level = int(param[key])
                "env":
                    env = param[key].split(",")
                "shooting":
                    match param[key]:
                        "enabled" :
                            shooting = true
                        "disabled" :
                            shooting = false
                        _: # invalid param value
                            return false
                "dists":
                    dists = int(param[key])
                "rots":
                    rots = int(param[key])
                "database":
                    match param[key]:
                        "read" :
                            read = true
                        "write" :
                            write = true
                        "read_write" :
                            read = true
                            write = true
                        _: # invalid param value
                            return false
                "agent_specific_param":
                    agent_specific_param = param[key].split(",")
                    
                _: # invalid param value
                    return false
                        
        #check if everything is valid
        if (n < 0 or not agent in all_agents or 
            level < 0 or level > MAX_LEVEL or not check_env() or
            dists < 0 or rots < 0):
            return false 
              
        # we don't need actions that have shooting if it was specified in the command line
        # or it is not necessary (there is nothing in the env to shoot)
        if not shooting or (not env.empty() and not "bugs" in env and not "viruses" in env):
            actions = actions.slice(0,2)
        
        # create necessary directories
        var directory = Directory.new()        
        if not directory.dir_exists("res://Command_outputs"):
            directory.make_dir("res://Command_outputs")        
        if read or write:
            if not directory.dir_exists("res://Agent_databases"):
                directory.make_dir("res://Agent_databases")        
        
    return true
        
func check_env():
    for elem in env:
        if not elem in all_env:
            return false
    return true

func add_score(score):
    num_of_games += 1
    scores_sum += score

func print_and_write_score(score, win):
    if not file.is_open():
        file.open("res://Command_outputs/" + command + ".txt", File.WRITE_READ)
      
    var data = "Game %d score: %.1f" % [num_of_games,score]
    
    write_data("%.1f" % score)
    
    if win:  
        data += " Game won!"  
        winning_score = score
    print(data)   
    

func print_and_write_ending():
    var ratio_of_wins = "Games won: %d/%d" % [wins, num_of_games]    
    var avg_score = "Average score: %.1f" % [scores_sum / num_of_games]
    # Note: we have to turn the microseconds to seconds, thus we devide by 1_000_000
    var avg_time_per_tick = "Average time per tick: " + String((end - start)/(num_of_ticks * 1_000_000))
    
    print(ratio_of_wins)
    print(avg_score)
    print(avg_time_per_tick)
    
    if winning_score > 0.0:
        write_data("winning_score %d" % winning_score)   
    else :
         write_data("winning_score unknown")   
        
    write_data("win_rate %d/%d" % [wins, num_of_games])    
    write_data("avg_score %.1f" % (scores_sum / num_of_games))
    write_data("previous_games %s" % agent_inst.get_n())
    file.close()

func write_data(data):
    file.seek_end()
    file.store_line(data)

func on_game_finished(score, ticks, win, time):
    # calculations
    num_of_ticks += ticks
    wins += int(win)
    add_score(score)
    # finish up
    print_and_write_score(score, win)
    agent_inst.end_game(score, time)        
    # start a new game
    play_game()
    
