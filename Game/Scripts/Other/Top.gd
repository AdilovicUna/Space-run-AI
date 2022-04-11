extends Node

var options = """
argument options:
    - n=int : number of games
    - agent=string : name of the agent [Static, Random]
    - help : displays help
"""

var all_agents = ["Static", "Random"]

var n = 100
var agent = "Static"

func _ready():
    # get args
    var unparsed_args = OS.get_cmdline_args()
    
    # show options
    if unparsed_args[0] == "--options":
        display_options()
    
    # parse agrs
    var args = {}
    for arg in unparsed_args:
        if arg.find("=") > 0:
            var key_value = arg.split("=")
            args[key_value[0].lstrip("--")] = key_value[1]
    
    # modify options based on args
    for key in args.keys():
        if key == "n":
            n = args[key]
        if key== "agent":
            agent = args[key]
    
    # check if everything is valid
    if n < 0 or not agent in all_agents:
        display_options()        
    
func display_options():
    print(options)
    get_tree().quit() 
