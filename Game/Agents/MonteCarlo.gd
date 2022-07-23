class_name MonteCarlo

# About the agent:
# on-policy, first visit, optimistic initial values

# IMPORTANT!
# agent's function move returns a list of 2 elements:
# - first element indicates the movement : -1 - left, 0 - just go forward, 1 - right
# - second element decides if Hans should shoot : 1 - yes, 0 - no

# total_return dictionary maps state_action → total return
var total_return = {}
# visits dictionary maps state_action → # of visits
var visits = {}

var last_action
var last_state
var episode_steps = []

# all possible actions
const ACTIONS = [[-1,0], [0,0], [1,0], [-1,1], [0,1], [1,1]]
# discounting value
const GAMA = 1

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

func Q(state, action):
    var state_action = get_state_action(state, action)
    return total_return[state_action] / visits[state_action]

# initialize
func start_game(dists, rots, types):
    var state_action
    
    for dist in dists:
        for rot in rots:
            for type in types:
                for action in ACTIONS:
                    state_action = get_state_action([dist * int(ceil(100.0 / dists)), 
                                                        rot * int(ceil(360.0 / rots)),
                                                        type], action)
                                        
                    # we initialize with the "optimistic initial values" approach
                    total_return[state_action] = 100.0
                    visits[state_action] = 1

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

func get_state_action(state, action):
    return ("[%d,%d,%s]_[%d,%d]" % 
                        [state[0], state[1], state[2], action[0], action[1]])
