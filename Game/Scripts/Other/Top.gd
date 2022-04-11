extends Node

var options = """
argument options:
    - n=int : number of games
    - agent=string : name of the agent [Static, Random]
    - help : displays help
"""

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
    if AutoLoad.set_param(args) == false:
        display_options()
    
    var n = AutoLoad.get_n()
        
    if n > 0:
        if AutoLoad.get_scores_count() > 0:
            print("Game %d score: %.1f" % [AutoLoad.get_scores_count(),AutoLoad.get_last_score()])
        n = AutoLoad.decrement_n()
        var _change = get_tree().change_scene("res://Scenes/Other/Main.tscn")   
    else:
        get_tree().quit()        
        print("Game %d score: %.1f" % [AutoLoad.get_scores_count(),AutoLoad.get_last_score()])    
        print("Average score: %.1f" % AutoLoad.get_avg_score())
    
func display_options():
    get_tree().quit() 
    print(options)
