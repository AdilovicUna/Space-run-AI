class_name SARSA
# About the agent:
# on-policy, optimistic initial values, epsilon-greedy policy

extends "res://Agents/LearningAgent.gd"


# move and remember  
func move(state, score):
    # we are still in the previous state
    if last_state == state:
        return last_action    
   
    new_action = .best_action(state)
            
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
    return init_agent(actions, read, write, filename, curr_n, debug)

# reset  
func start_game(eval):
    start(eval)

# update
func end_game(final_score, _final_time):
    if not is_eval_game:
        var state_action = get_state_action(last_state,last_action)
        var R = final_score - last_score
        update_dicts(state_action, '', R, true)
        epsilon_update()

# write
func save(write):
    ad_write(write)


func Q(state, action):
    var state_action = get_state_action(state, action)
    if not (state_action in q.keys()):
        q[state_action] = INITIAL_OPTIMISTIC_VALUE
        visits[state_action] = 0
        
    return q[state_action]
    
func update_dicts(state_action, new_state_action, R, terminal = false):
    if not (state_action in q.keys()):
        q[state_action] = INITIAL_OPTIMISTIC_VALUE
        visits[state_action] = 0
        
    visits[state_action] += 1
    var alpha = 1.0 / visits[state_action]
    var new_state_val = 0 if terminal else q[new_state_action]
    q[state_action] += alpha * (R + GAMMA * new_state_val - q[state_action])    
    
func parse_line(line):   
    q[line[0]] = float(line[1])
    visits[line[0]] = float(line[2])

func store_data(data):
    for elem in q.keys():
        data += "%s:%s:%s\n" % [elem, q[elem], visits[elem]]
    return data

func all_state_actions():
    return q.keys()
    
