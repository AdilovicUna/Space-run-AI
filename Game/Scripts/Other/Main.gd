extends Node

const MAX_LEVEL = 15

var options = """
argument options:
    - n=int :               number of games
    
    - stoppingPoint=int :   stop after the agent wins this many consecutive games 
    
    - agent=string :        name of the agent
                            options: [Keyboard, Static, Random, MonteCarlo, SARSA, QLearning, ExpectedSARSA, DoubleQLearning]
                            sub-options (only for the agents listed below):
                                MonteCarlo, SARSA, QLearning, ExpectedSARSA, DoubleQLearning
                                =[float, float, float, float] : 
                                [gam (range [0,1]), eps (range [0,1]), epsFinal (range [0,1]), initOptVal (range [0,~))]
                                eg. use: \"MonteCarlo:eps=0.1,gam=0.2\"
            
    - level=int :           number of the level to start from 
                            options: [1, ... , 10]
                        
    - env=[string] :        list of obstacles that will be chosen in the game 
                            options (any subset of): [Traps, Bugs, Viruses, Tokens, 
                                                      I, O, MovingI, X, Walls, Hex, 
                                                      HexO, Balls, Triangles, HalfHex,
                                                      Worm, LadybugFlying, LadybugWalking,
                                                      Rotavirus, Bacteriophage]
                                            
    - shooting=string :     enable or disable shooting 
                            options: [enabled, disabled]
                        
    - dists=int :           number of states in a 100-meter interval
    
    - rots=int :            number of states in 360 degrees rotation
    
    - agentSeedVal=int :    seed value for the random moves the agent takes
    
    - database=string:      read = read the data for this command from an existing file 
                            write = update the data after the command is executed 
                            options: [read, write, read_write]
                            Note: will not influence the following agents: Keyboard, Static, Random

    - ceval=bool :          performs continuous evaluation
                            options: [true,false]
                                
    - debug=bool :          display debug print statements
                            options: [true,false]
             
    - options :             displays options
"""

var game_scene = preload("res://Scenes/Other/Game.tscn")
var game

var all_agents = ["Keyboard", "Static", "Random", "MonteCarlo", "SARSA", "QLearning", "ExpectedSARSA", "DoubleQLearning"]
var all_env = [ "Traps", "Bugs", "Viruses", "Tokens", 
                "I", "O", "MovingI", "X", "Walls", "Hex", 
                "HexO", "Balls", "Triangles", "HalfHex",
                "Worm", "LadybugFlying", "LadybugWalking",
                "Rotavirus", "Bacteriophage"]

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
var ceval = false
var debug = false
var ad_ver = 0
var agent_seed_val = 0
var stopping_point = 10

var agent_inst = Keyboard.new()

var is_eval_game
var scores_sum = 0.0
var num_of_games = 0

var paramSet = false

var start
var end
var num_of_ticks = 0.0
var wins = 0
var winning_score = 0.0

var consecutive_games_won = 0

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
        # set seed val for an agent
        agent_inst.set_seed_val(agent_seed_val)
        if not agent_inst.init(actions, read, write, command, n, debug):
            print("Something went wrong, please try again")
            print(options)
            get_tree().quit()

        if ceval:
            n *= 2      # play n learning games + n evaluation games
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
    elif n > 0 and consecutive_games_won < stopping_point:
        n -= 1
        game = game_scene.instance()
        set_param_in_game()
        is_eval_game = ceval and n % 2 == 0
        if ceval:
            print("\n%s game:" % ("evaluation" if is_eval_game else "learning"))
        agent_inst.start_game(is_eval_game)
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
        "QLearning":
            agent_inst = QLearning.new()
        "ExpectedSARSA":
            agent_inst = ExpectedSARSA.new()
        "DoubleQLearning":
            agent_inst = DoubleQLearning.new()
            
            
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
                            "shooting=" + String(shooting), "dists=" + String(dists), "rots=" + String(rots), "agentSeedVal=" + String(agent_seed_val)]
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
                "ceval":
                    match param[key]:
                        "true" :
                            ceval = true
                        "false" :
                            ceval = false
                        _: # invalid param value
                            return false
                "debug":
                    match param[key]:
                        "true" :
                            debug = true
                        "false" :
                            debug = false
                        _: # invalid param value
                            return false
                "agentSeedVal":
                    agent_seed_val = int(param[key])   
                "stoppingPoint":
                    stopping_point = int(param[key])     
                _: # invalid param value
                    return false
                        
        # check if everything is valid
        if (n < 0 or not agent in all_agents or 
            level < 0 or level > MAX_LEVEL or not check_env() or
            dists < 0 or rots < 0 or stopping_point < 1):
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
    #command outputs format:
    # f_c.txt
    # c = command outputs counter
    var dir = Directory.new()
    var file_names = []
    var path = "res://Command_outputs"
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
        
    rename_files_helper(file_names, path)

func rename_files_helper(file_names, path):
    var dir = Directory.new()
    if dir.open(path) == OK:
        for i in range(len(file_names) - 1, -1, -1):
            var file_name = file_names[i]
            var file_name_comp = file_name.split('_')
            var last = len(file_name_comp) - 1
            file_name_comp[last] = file_name_comp[last].substr(0,len(file_name) - 4)
            
            var new_file_name
        
            # update Command_outputs counter
            file_name_comp[1] = String(int(file_name_comp[1]) + 1)
            
            new_file_name = (file_name_comp[0] + '_' +
                                file_name_comp[1] +
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
    if not file.is_open() and (write or read):
        # new command outputs will be 0 and version of the agent_databases we are using is specified
        file.open("res://Command_outputs/" + command + '_0' + ".txt", File.WRITE_READ) 
      
    var data = "Game %d score: %.1f" % [num_of_games,score]
    
    if not ceval or is_eval_game:
        write_data("%.1f" % score)
        
    
    if win:  
        data += " Game won!"  
        winning_score = score
    print(data)   

func write_agent_databases():
    write_data("")
    var ad_file = File.new()
    ad_file.open("res://Agent_databases/" + command + ".txt", File.READ)
    if ad_file.is_open():
        var line = ""
        var read_n = false
        while not ad_file.eof_reached():
            line = ad_file.get_line()
            if line.empty():
                continue
            if not read_n:
                read_n = true
            else:
                write_data(line,true)
        ad_file.close()

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
    
    if write or read:
        write_agent_databases()
        file.close()

func write_data(data, writing_agent_databases = false):
    if not writing_agent_databases and not read and not write:
        return
        
    file.seek_end()
    file.store_line(data)

func on_game_finished(score, ticks, win, time):
    # calculations
    num_of_ticks += ticks
    if not ceval or is_eval_game:
        wins += int(win)
        add_score(score)
        # count how many games in a row have been won
        consecutive_games_won = (consecutive_games_won + 1) * int(win)
    # finish up
    print_and_write_score(score, win)
    agent_inst.end_game(score, time)        
    # start a new game
    play_game()
    
