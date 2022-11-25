extends Node

const MAX_LEVEL = 10

var options = """
argument options:
    - n=int :               number of games
    
    - agent=string :        name of the agent
                            options: [Keyboard, Static, Random, MonteCarlo, SARSA]
                            sub-options (only for the agents listed below):
                                MonteCarlo=[float, float, float, float] : 
                                    [gam (range [0,1]), eps (range [0,1]), epsDec (range [0,1]), initOptVal [0,~)]
                                    eg. use: "MonteCarlo:eps=0.1,gam=0.2"
                                SARSA=[float, float, float, float] : 
                                    [gam (range [0,1]), eps (range [0,1]), epsDec (range [0,1]), initOptVal [0,~)]
                                    eg. use: "SARSA:eps=0.1,gam=0.2"
                        
    - level=int :           number of the level to start from 
                            options: [1, ... , 10]
                        
    - env=[string] :        list of obstacles that will be chosen in the game 
                            options (any subset of): [traps, bugs, viruses, tokens, I, O, MovingI, X, 
                                                      Walls, Hex, HexO, Balls, Triangles, HalfHex]
                                            
    - shooting=string :     enable or disable shooting 
                            options: [enabled, disabled]
                        
    - dists=int :           number of states in a 100-meter interval
    
    - rots=int :            number of states in 360 degrees rotation
    
    - database=string:      read = read the data for this command from an existing file 
                            write = update the data after the command is executed 
                            options: [read, write, read_write]
                            Note: will not influence the following agents: Keyboard, Static, Random
                            sub-option:
                                version=int - specifies Agent_databases vesion of the file
                                eg. use: "database=read:1"
                                   

    - debug=bool :          display debug print statements
                            optionsL [true,false]
             
    - options :             displays options
"""

var game_scene = preload("res://Scenes/Other/Game.tscn")
var game

var all_agents = ["Keyboard", "Static", "Random", "MonteCarlo", "SARSA"]
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
var debug = false
var ad_ver = 0

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
            var value = slice(key_value, 1, len(key_value))
            args[key_value[0]] = value.join("=")
            
    # set param, if something went wrong, show options
    if set_param(args) == false:
        display_options()
    else:
        start = OS.get_ticks_usec()
        instance_agent()
        build_filename()
        rename_files()
        if not agent_inst.init(actions, read, write, command + '_' + String(ad_ver), n, debug):
            print("Something went wrong, please try again")
            print(options)
            get_tree().quit()
        play_game()

func slice(array, start_index, end_index):
    # end_index is not included
    var result = []
    for i in range(start_index, end_index):
        if i >= len(array):
            return result
        result.append(array[i])
    return PoolStringArray(result)
    
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
    game.set_debug(debug)
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
        "SARSA":
            agent_inst = SARSA.new()


func display_options():
    get_tree().quit() 
    print(options)

func build_filename():
    # we sort it so that we would always get the same filename in build_filename()    
    var sorted_env = Array(env)
    sorted_env.sort()
    if sorted_env == []:
        sorted_env = "all"
    
    var sorted_agent_specific_param = agent_inst.get_and_set_agent_specific_parameters(agent_specific_param)
    sorted_agent_specific_param.sort()
    
    command = PoolStringArray(["agent=" + String(agent), "agentSpecParam=" + String(sorted_agent_specific_param), "level=" + String(level), "env=" + String(sorted_env), 
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
                    var temp = param[key].split(":")
                    agent = temp[0]
                    if len(temp) > 1:
                        agent_specific_param = temp[1].split(",")    
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
                    var temp = param[key].split(":")
                    match temp[0]:
                        "read" :
                            read = true
                        "write" :
                            write = true
                        "read_write" :
                            read = true
                            write = true
                        _: # invalid param value
                            return false
                    if len(temp) > 1:
                        ad_ver = int(temp[1])
                "debug":
                    match param[key]:
                        "true" :
                            debug = true
                        "false" :
                            debug = false
                        _: # invalid param value
                            return false
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

func rename_files():
    # to avoid overwriting a file in Agent_databases 
    # and having wrong policies displayed in plots 
    # we will rename all previous files
    # in Agent_databases and Command_outputs
    
    # format: f_c1_c2.txt
    # c1 = agent_databases counter
    # c2 = command_outputs counter
    if write:
        ad_ver += 1
        rename_files_helper("res://Agent_databases", true, write)
    rename_files_helper("res://Command_outputs", false, write)

func rename_files_helper(path, ad, writeOpt):
    print(path)
    var dir = Directory.new()
    var file_names = []
    if dir.open(path) == OK:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if not dir.current_is_dir():
                if command in file_name:
                    file_names.append(file_name)
            file_name = dir.get_next()
    else:
        print("An error occurred when trying to access the path.")
        
    rename_files_helper_helper(file_names, path, ad, writeOpt)
    
func rename_files_helper_helper(file_names, path, ad, writeOpt):
    var dir = Directory.new()
    if dir.open(path) == OK:
        for i in range(len(file_names) - 1, -1, -1):
            var file_name = file_names[i]
            var file_name_comp = file_name.split('_')
            var last = len(file_name_comp) - 1
            file_name_comp[last] = file_name_comp[last].substr(0,len(file_name) - 4)
            
            var new_file_name
            if ad:
                new_file_name = (file_name_comp[0] + '_' +
                                    String(int(file_name_comp[1]) + 1) + 
                                    ".txt")
            else:
                if writeOpt:
                    # we update Agent_databases counter as well
                    file_name_comp[1] = String(int(file_name_comp[1]) + 1)
                # update Command_outputs counter
                file_name_comp[2] = String(int(file_name_comp[2]) + 1)
                
                new_file_name = (file_name_comp[0] + '_' +
                                    file_name_comp[1] + '_' +
                                    file_name_comp[2] +
                                    ".txt")
                
            dir.rename(file_name,new_file_name)
            
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
        # new command outputs will be 0 and version of the ad we are using is specified
        file.open("res://Command_outputs/" + command + '_0_' + String(ad_ver) + ".txt", File.WRITE_READ) 
      
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
    
