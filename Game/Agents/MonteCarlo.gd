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

# all possible actions
var ACTIONS = []
# name of the file we will read from and right to
var FILENAME = ""
# discounting value
const GAMMA = 1

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
    episode_steps.append([get_state_action(last_state, last_action), score])
    
    return last_action

# initialize
func init(actions, filename):
    ACTIONS = actions
    FILENAME = filename
    
    if FILENAME != "":
        var file = File.new()
        file.open("res://Agent_databases/" + FILENAME + ".txt", File.READ)
        if file.is_open():
            var line = ""
            var reading_total_return = true
            while not file.eof_reached():
                line = file.get_line()
                if line.empty():
                    continue
                    
                if line == "---":
                    reading_total_return = false
                elif reading_total_return:
                    line = line.split(':')
                    total_return[line[0]] = float(line[1])
                else:
                    line = line.split(':')
                    visits[line[0]] = int(line[1])
                    
            file.close()
        
# reset
func start_game():
    episode_steps = []
    last_state = null
    last_state = null

# update
func end_game(final_score):
    var seen_state_actions = []
    for step in episode_steps:
        var state_action = step[0]
        var score = step[1]
        
        # since we are using the first visit approach,
        # we only need to remember the first occurance of this state_action
        if not state_action in seen_state_actions:
            seen_state_actions.append(state_action)
            total_return[state_action] += (final_score - score)
            visits[state_action] += 1

# write
func save():
    if FILENAME == "":
        return

    var data = ""
    
    for elem in total_return:
        data += (String(elem) + ':' + String(total_return[elem]) + '\n')
        
    data += "---\n"
    
    for elem in visits:
        data += (String(elem) + ':' + String(visits[elem]) + '\n')
        
    var file = File.new()
    file.open("res://Agent_databases/" + FILENAME + ".txt", File.WRITE)
    file.store_string(data)
    file.close()
  
func Q(state, action):
    var state_action = get_state_action(state, action)
    if not (state_action in total_return):
        total_return[state_action] = 100.0
        visits[state_action] = 1
    return total_return[state_action] / visits[state_action]

func get_state_action(state, action):
    return ("[%d,%d,%s]_[%d,%d]" % 
                        [state[0], state[1], state[2], action[0], action[1]])
