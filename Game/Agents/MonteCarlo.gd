class_name MonteCarlo

# About the agent:
# on-policy, first visit, optimistic initial values

# IMPORTANT!
# agent's function move returns a list of 2 elements:
# - first element indicates the movement : -1 - left, 0 - just go forward, 1 - right
# - second element decides if Hans should shoot : 1 - yes, 0 - no

# variables to write to a text file
# total_return dictionary maps state_action → total return
var total_return = {}
# visits dictionary maps state_action → # of visits
var visits = {}

# variables that need to reset after each episode
var last_action
var last_state
var episode_steps = []

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
            last_action = action
   
    # remember relevant infromation
    last_state = state
    episode_steps.append(Step.new(get_state_action(last_state, last_action), score, OS.get_ticks_msec() / 1000.0))
   
    return last_action

# initialize
func init(actions, read, filename, curr_n, agent_specific_param):
    ACTIONS = actions
    FILENAME = filename
    
    if agent_specific_param != []:
        if len(agent_specific_param) != 2:
            return false
            
        GAMMA = float(agent_specific_param[0])
        INITIAL_OPTIMISTIC_VALUE = float(agent_specific_param [1])
    
    if GAMMA < 0 or GAMMA > 1 or INITIAL_OPTIMISTIC_VALUE < 0:
        return false
    
    new_n = curr_n
   
    if not read:
        return true
   
    var file = File.new()
    file.open("res://Agent_databases/" + FILENAME + ".txt", File.READ)
    if file.is_open():
        var line = ""
        var line2 = ""
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
                line2 = line[1].split('/')
                total_return[line[0]] = float(line2[0])
                visits[line[0]] = int(line2[1])
               
        file.close()
    else:
        return false
       
    return true
       
# reset
func start_game():
    episode_steps = []
    last_state = null
    last_state = null

# update
func end_game(final_score, final_time):
    var G = 0
    episode_steps.append(Step.new("", final_score, final_time))
    
    for i in range(len(episode_steps) - 2,-1,-1):
        var curr_step = episode_steps[i]
        var next_step = episode_steps[i+1]
        var R = (next_step.score - curr_step.score)
        G = (R / log(GAMMA)) * (pow(GAMMA,next_step.time) - pow(GAMMA,curr_step.time)) * (R + G)
        
        # since we are using the first visit approach,
        # we only need the first occurrence  of this state_action
        if is_first_occurrence (curr_step.state_action, i):
            total_return[curr_step.state_action] += G
            visits[curr_step.state_action] += 1
   
# write
func save(write):
    if not write:
        return

    var data = ""
   
    # remember how many games have been played
    data += String(n + new_n) + '\n'
   
    for elem in total_return:
        data += (String(elem) + ':' + String(total_return[elem]) + '/' + String(visits[elem]) + '\n')
       
    var file = File.new()
    file.open("res://Agent_databases/" + FILENAME + ".txt", File.WRITE)
    file.store_string(data)
    file.close()
 
func Q(state, action):
    var state_action = get_state_action(state, action)
    if not (state_action in total_return):
        total_return[state_action] = INITIAL_OPTIMISTIC_VALUE
        visits[state_action] = 1
    return total_return[state_action] / visits[state_action]

func get_state_action(state, action):
    return ("[%d,%d,%s]_[%d,%d]" %
                        [state[0], state[1], state[2], action[0], action[1]])

func get_n():
    return String(n)
   
func is_first_occurrence (state_action, index):
    for i in range(len(episode_steps)):
        var step = episode_steps[i]
        if step.state_action == state_action:
            return i == index
