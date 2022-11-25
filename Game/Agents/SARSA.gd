class_name SARSA

var rand = RandomNumberGenerator.new()

# About the agent:
# on-policy, first visit, optimistic initial values, epsilon-greedy policy

# IMPORTANT!
# agent's function move returns a list of 2 elements:
# - first element indicates the movement : -1 - left, 0 - just go forward, 1 - right
# - second element decides if Hans should shoot : 1 - yes, 0 - no

var q = {}

var visits = {}

# variables that need to reset after each episode
var new_action
var last_action
var last_state
var last_score

# how many games are remembered in this file
var n = 0
var new_n = 0

# all possible actions
var ACTIONS = []
# name of the file we will read from and right to
var FILENAME = ""
# discounting value
var GAMMA = 1.0
var INITIAL_OPTIMISTIC_VALUE = 0.0
var EPSILON = 0.2   
var EPSILON_DECREASE = 0.98

const FINAL_EPSILON_VAL = 0.0001

var DEBUG = false

# move and remember  
func move(state, score):
    # we are still in the previous state
    if last_state == state:
        return last_action    
   
    # next action should be the one with the maximum value of Q function
    var max_q = 0.0
    for action in ACTIONS:
        if Q(state, action) > max_q:
            max_q = Q(state, action)
            new_action = action
            
    var epsilon_action = rand.randf_range(0,1) < EPSILON
    if epsilon_action:
        while true:
            var rand_action = ACTIONS[rand.randi_range(0,len(ACTIONS) - 1)]            
            if new_action != rand_action:
                new_action = rand_action
                break
    
    # update q
    if last_state != null and last_action != null:      
        var state_action = get_state_action(last_state,last_action)
        var new_state_action = get_state_action(state,new_action)
        var R = score - last_score
        update_dicts(state_action, new_state_action, R)
    
    last_state = state
    last_action = new_action
    last_score = score
    return last_action

# initialize
func init(actions, read, write, filename, curr_n, debug):
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
                q[line[0]] = float(line[1])
                #visits[line[0]] = float(line[2])
                visits[line[0]] = 0
               
        file.close()
    else:
        return false
       
    return true
       
# reset
func start_game():
    new_action = null
    last_action = null
    last_state = null
    last_score = 0

# update
func end_game(_final_score, _final_time):
    # epsilon will decrease on each game
    # so that by the end it is 0.001
    # (random action will occur 1/1000)
    if EPSILON > 0:
        EPSILON *= EPSILON_DECREASE
        
    if DEBUG:    
        print('\nepsilon = %.3f' % EPSILON)   

# write
func save(write):
    if not write:
        return

    var data = ""
   
    # remember how many games have been played
    data += String(n + new_n) + '\n'
   
    for elem in q.keys():
        data += "%s:%s:%s\n" % [elem, q[elem], visits[elem]]
    
    var file = File.new()
    file.open("res://Agent_databases/" + FILENAME + ".txt", File.WRITE)
    file.store_string(data)
    file.close()

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
 
func Q(state, action):
    var state_action = get_state_action(state, action)
    if not (state_action in q.keys()):
        q[state_action] = INITIAL_OPTIMISTIC_VALUE
        visits[state_action] = 0
        
    return q[state_action]
    
func update_dicts(state_action, new_state_action, R):
    if not (state_action in q.keys()):
        q[state_action] = INITIAL_OPTIMISTIC_VALUE
        visits[state_action] = 0
        
    visits[state_action] += 1
    var alpha = 1.0 / visits[state_action]
    q[state_action] += alpha * (R + GAMMA * q[new_state_action] - q[state_action])    

        

func get_state_action(state, action):
    return ("[%d,%d,%s]_[%d,%d]" %
                        [state[0], state[1], state[2], action[0], action[1]])

func get_n():
    return String(n)
