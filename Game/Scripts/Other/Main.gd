extends Node


var options = """
argument options:
    - n=int : number of games
    - agent=string : name of the agent [Static, Random]
    - options : displays options
"""

var game_scene = preload("res://Scenes/Other/Game.tscn")
var game

var all_agents = ["None", "Static", "Random"]

var n = 100
var agent = "None"
var scores_sum = 0.0
var scores_count = 0
var last_score = 0.0

var paramSet = false

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
        play_game()
    
func play_game():     
    if n > 0:
        n -= 1
        game = game_scene.instance()
        game.set_agent(agent)
        add_child(game)
    else:
        print_avg_score()
        get_tree().quit()        
        

func display_options():
    get_tree().quit() 
    print(options)

func set_param(param):
    if not paramSet:
        paramSet = true
        # modify options based on args
        for key in param:
            if key == "n":
                n = int(param[key])
            if key== "agent":
                agent = param[key]
    
        #check if everything is valid
        if n < 0 or not agent in all_agents:
            return false   

func add_score(score):
    scores_count += 1
    last_score = score
    scores_sum += score

func print_score(score):
    print("Game %d score: %.1f" % [scores_count,last_score])   

func print_avg_score():
    print("Average score: %.1f" % [scores_sum / scores_count])
        
func on_game_finished(score):
    add_score(score)
    print_score(score)
    play_game()
    
