class_name DoubleQLearning
# About the agent:
# on-policy, optimistic initial values, epsilon-greedy policy

extends "res://Agents/LearningAgent.gd"

var q2 = {}
var prev_time = 0

func move(state, score, num_of_ticks):
    # we are still in the previous state
    if last_state == state:
        return last_action    
   
    last_action = choose_action(.best_action(state), num_of_ticks)     
    
    # update q
    if last_state != null and last_action != null:      
        var state_action = get_state_action(last_state,last_action)
        var R = score - last_score
        update_dicts(state_action, state, R, (num_of_ticks * 33) / 1000.0)
            
    last_state = state
    last_score = score
    prev_time = (num_of_ticks * 33) / 1000.0
    return last_action

# initialize
func init(actions, read, write, filename, curr_n, debug):
    return init_agent(actions, read, write, filename, curr_n, debug)
   
# reset  
func start_game(eval):
    start(eval)

# update 
func end_game(final_score, final_time):
    if not is_eval_game:
        var state_action = get_state_action(last_state,last_action)
        var R = final_score - last_score
        update_dicts(state_action, '', R, final_time, true)
        epsilon_update()

# write
func save(write):
    ad_write(write)
    
func parse_line(line):   
    #state_action:q1:q2:visits
    line = line.split(':')
    
    if line[1] != '':
        q[line[0]] = float(line[1])
        
    if line[2] != '':
        q2[line[0]] = float(line[2])
        
    visits[line[0]] = float(line[3])

func store_data(data):
    for elem in visits.keys():
        var q1_elem = '' if not elem in q.keys() else q[elem]
        var q2_elem = '' if not elem in q2.keys() else q2[elem]
        data += "%s:%s:%s:%s\n" % [elem, q1_elem, q2_elem, visits[elem]]
    return data
    
func all_state_actions():
    return visits.keys()

func Q(state, action):
    var state_action = get_state_action(state, action)
    
    if not (state_action in q.keys()):
        q[state_action] = INITIAL_OPTIMISTIC_VALUE
        
    if not (state_action in visits.keys()):
        visits[state_action] = 0
        
    if not (state_action in q2.keys()):
        q2[state_action] = INITIAL_OPTIMISTIC_VALUE
    
    return q[state_action] + q2[state_action]

func update_dicts(state_action, state, R, curr_time, terminal = false):        
    if not (state_action in visits.keys()):
        visits[state_action] = 0
    
    visits[state_action] += 1
    
    var alpha = 1.0 / visits[state_action]
    var new_gamma = pow(GAMMA,curr_time - prev_time)
        
    if rand.randf_range(0,1) < 0.5:
        if not (state_action in q.keys()):
            q[state_action] = INITIAL_OPTIMISTIC_VALUE
        
        var new_state_val = 0 if terminal else q2[get_state_action(state,.best_action(state,q))]
        q[state_action] += alpha * (new_gamma * (R + new_state_val) - q[state_action])
        
    else:
        if not (state_action in q2.keys()):
            q2[state_action] = INITIAL_OPTIMISTIC_VALUE
            
        var new_state_val = 0 if terminal else q[get_state_action(state,.best_action(state,q2   ))]
        q2[state_action] += alpha * (new_gamma * (R + new_state_val) - q2[state_action])
    
