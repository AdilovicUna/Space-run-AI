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
var FINAL_EPSILON_VAL = 0.0001
var EPSILON_DECREASE

var DEBUG = false

# variables that need to reset after each episode
var last_action
var last_state
var new_action
var last_score
var episode_steps = []
var is_eval_game

var prev_msec = 0

var epsilon_action = false # needed in MonteCarlo but is changed in this class

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
                parse_line(line)
               
        file.close()
    else:
        return false
       
    return true

func start(eval):
    episode_steps = []
    last_action = null    
    new_action = null
    last_state = null
    last_score = 0
    is_eval_game = eval

func Q(_state, _action):
    pass    # subclass must implement

func best_action(state, specific_dict = null):
    # next action should be the one with the maximum value of Q function
    var max_q = 0.0
    var best = null
    for action in ACTIONS:
        var new_q
        if specific_dict == null:
            new_q = Q(state, action)
        else:
            new_q = specific_dict[get_state_action(state, action)]
        if new_q >= max_q:
            max_q = new_q
            best = action
    return best

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
    
    print('epsilon = %.4f' % EPSILON)
    if DEBUG:    
        show_policy()

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
            "epsFinal":
                FINAL_EPSILON_VAL = float(param[1])
            _: # invalid param value
                    return false
                        
    return ["gam=" + String(GAMMA), 
            "eps=" + String(EPSILON), 
            "epsFinal=" + String(FINAL_EPSILON_VAL), 
            "initOptVal=" + String(INITIAL_OPTIMISTIC_VALUE)]
 

func get_state_action(state, action):
    return ("[%d,%d,%s]_[%d,%d]" %
                        [state[0], state[1], state[2], action[0], action[1]])

func get_n():
    return String(n)

func parse_line(_line):
    pass # subclass must implement

func store_data(_data):
    pass # subclass must implement

func all_state_actions():
    pass # subclass must implement

const MOVES_MAP = {
    '[-1, 0]': '←', '[0, 0]': '↑', '[1, 0]': '→',
    '[-1, 1]': '←*', '[0, 1]': '↑*', '[1, 1]': '→*'
}

var last_policy = null

func show_policy():
    var dists_d = {}
    var rots_d = {}
    var obstacles_d = {}
    for sa in all_state_actions():    # e.g. "[0,210,I]_[-1,0]"
        var words = sa.split("_")
        var left = words[0].trim_prefix("[").trim_suffix("]").split(",")
        dists_d[int(left[0])] = null
        rots_d[int(left[1])] = null
        obstacles_d[left[2]] = null

    var dists = dists_d.keys()
    dists.sort()
    var rots = rots_d.keys()
    rots.sort()
    var obstacles = obstacles_d.keys()
    obstacles.sort()

    var policy = {}
    var s = "        "
    for rot in rots:
        s += "%4d" % rot
    print(s)
    for obstacle in obstacles:
        for dist in dists:
            s = "(%d, %s)" % [dist, obstacle]
            s = "%8s" % s
            for rot in rots:
                var state = str([dist, obstacle, rot])
                var action = best_action([dist, rot, obstacle])
                policy[state] = action
                var t
                if last_policy != null and last_policy.get(state) != action:
                    t = "(%s)" % MOVES_MAP[str(action)]
                else:
                    t = MOVES_MAP[str(action)] + " "
                s += "%4s" % t
            print(s)
    last_policy = policy

func choose_action(action, num_of_ticks):
    var curr_msec = num_of_ticks * 33
    epsilon_action = false
    if not is_eval_game:
        if (curr_msec - prev_msec) >= 50:
            prev_msec = curr_msec
            epsilon_action = rand.randf_range(0,1) < EPSILON
            if epsilon_action:
                action = ACTIONS[rand.randi_range(0,len(ACTIONS) - 1)]  
    return action
