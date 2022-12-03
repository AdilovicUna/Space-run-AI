class_name LearningAgent
# this is a superclass for the MonteCarlo and SARSA agents

# IMPORTANT!
# agent's function move returns a list of 2 elements:
# - first element indicates the movement : -1 - left, 0 - just go forward, 1 - right
# - second element decides if Hans should shoot : 1 - yes, 0 - no

var rand = RandomNumberGenerator.new()

# variables to write to a text file
# total_return dictionary maps state_action → total return
var total_return = {}
# visits dictionary maps state_action → # of visits
var visits = {}
var q = {}

# how many games are remembered in this file
var n = 0
var new_n = 0

# all possible actions
var ACTIONS = []
# name of the file we will read from and right to
var FILENAME = ""
# discounting value
var GAMMA = 1.0
var INITIAL_OPTIMISTIC_VALUE = 100.0
var EPSILON = 0.2   
var EPSILON_DECREASE

const FINAL_EPSILON_VAL = 0.0001

var DEBUG = false

# variables that need to reset after each episode
var last_action
var last_state
var new_action
var last_score
var episode_steps = []

func init_agent(actions, read, write, filename, curr_n, debug):
     # so that we can replicate experiments
    rand.seed = 0
    
    DEBUG = debug
    
    ACTIONS = actions
    FILENAME = filename
                        
    if (GAMMA < 0 or GAMMA > 1 or 
        INITIAL_OPTIMISTIC_VALUE < 0 or
        EPSILON < 0 or EPSILON > 1):
        return false
    
    if DEBUG:
        print('\nepsilon = %.3f' % EPSILON)  
    
    if EPSILON == 0.0:
        EPSILON_DECREASE = 0.0
    else:
        EPSILON_DECREASE = pow(FINAL_EPSILON_VAL / EPSILON, 1.0 / curr_n)
    
    new_n = curr_n
    
    if not read:
        return true
    
    if not write: 
        # we just want to check how good agent is without any randomness
        EPSILON = 0
        
    var file = File.new()
    file.open("res://Agent_databases/" + FILENAME + ".txt", File.READ)
    if file.is_open():
        var line = ""
        var read_n = false
        while not file.eof_reached():
            line = file.get_line()
            if line.empty():
                continue
            if not read_n:
                read_n = true
                n = int(line)
            else:
                line = line.split(':')
                parse_line(line)
               
        file.close()
    else:
        return false
       
    return true

func start():
    episode_steps = []
    last_action = null    
    new_action = null
    last_state = null
    last_score = 0

func ad_write(write):
    if not write:
        return

    var data = ""
   
    # remember how many games have been played
    data += String(n + new_n) + '\n'
   
    data = store_data(data)
    
    var file = File.new()
    
    file.open("res://Agent_databases/" + FILENAME + ".txt", File.WRITE)
    file.store_string(data)
    file.close()

func epsilon_update():
    # epsilon will decrease on each game
    # so that by the end it is 0.0001
    # (random action will occur 1/10000)
    if EPSILON > 0:
        EPSILON *= EPSILON_DECREASE
            
    if DEBUG:    
        print('\nepsilon = %.3f' % EPSILON) 

func get_and_set_agent_specific_parameters(agent_specific_param):
    for param in agent_specific_param:
        param = param.split("=")
        match param[0]:
            "gam":
                GAMMA = float(param[1])
            "eps":
                EPSILON = float(param[1])
            "initOptVal":
                INITIAL_OPTIMISTIC_VALUE = float(param[1])
            _: # invalid param value
                    return false
                        
    return ["gam=" + String(GAMMA), "eps=" + String(EPSILON), "initOptVal=" + String(INITIAL_OPTIMISTIC_VALUE)]
 

func get_state_action(state, action):
    return ("[%d,%d,%s]_[%d,%d]" %
                        [state[0], state[1], state[2], action[0], action[1]])

func get_n():
    return String(n)

func parse_line(_line):
    pass

func store_data(_data):
    pass
