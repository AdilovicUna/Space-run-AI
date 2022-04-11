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
    if AutoLoad.setParam(args) == false:
        display_options()
    
    var n = AutoLoad.getN()
        
    if n > 0:
        n = AutoLoad.decrementN()
        get_tree().change_scene("res://Scenes/Other/Main.tscn")   
    else:
        get_tree().quit()        
        var avg = "Average score: %.1f" % AutoLoad.getAvgScore()
        print(avg) 
    
func display_options():
    get_tree().quit() 
    print(options)
