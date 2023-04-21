class_name TDAgent

extends "res://Agents/LearningAgent.gd"

var prev_time = 0

# move and remember  
func move(state, score, num_of_ticks):
    # we are still in the previous state
    if last_state == state:
        return last_action    
    
    new_action = choose_action(.best_action(state))     
    
    # update q
    if last_state != null and last_action != null:      
        var last_state_action = get_state_action(last_state,last_action)
        var new_state_action = get_update(state, new_action, .best_action(state))
        var R = score - last_score
        update_dicts(last_state_action, new_state_action, R, num_of_ticks)
    
        episode_steps.append(Step.new(
                get_state_action(state, last_action), score, num_of_ticks, epsilon_action))

    last_state = state
    last_action = new_action    
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
    if DEBUG:
        var n_steps = len(episode_steps)
        var s = "  last actions: "
        for i in range(max(n_steps - 7, 0), n_steps):
            var step = episode_steps[i]
            if step.epsilon_action:
                s += "*"
            s += String(step.state_action) + " "
        print(s)
        print("Agents database:")
        print(store_data())

    if not is_eval_game:
        var state_action = get_state_action(last_state,last_action)
        var R = final_score - last_score
        update_dicts(state_action, '', R, final_time, true)
        epsilon_update()

# write
func save(write):
    ad_write(write)

func Q(state, action):
    var state_action = get_state_action(state, action)
    add_state_action(state_action)

    return q[state_action]
    
func update_dicts(last_state_action, new_state_action, R, curr_time, terminal = false):
    add_state_action(last_state_action)
    visits[last_state_action] += 1
    
    var alpha = 1.0 / visits[last_state_action]
    var new_state_val = 0 if terminal else new_state_action
    var new_gamma = pow(GAMMA,curr_time - prev_time)
    q[last_state_action] += alpha * (new_gamma * (R + new_state_val) - q[last_state_action])

func add_state_action(state_action):
    if not (state_action in q.keys()):
        q[state_action] = INITIAL_OPTIMISTIC_VALUE
        visits[state_action] = 0

func get_update(_state, _new_action, _best_action):
    pass # subclass must implement
    
func parse_line(line):   
    line = line.split(':')
    q[line[0]] = float(line[1])
    visits[line[0]] = float(line[2])

func store_data(data = ""):
    for elem in q.keys():
        data += "%s:%s:%s\n" % [elem, q[elem], visits[elem]]
    return data

func all_state_actions():
    return q.keys()
    

        