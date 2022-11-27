class_name MonteCarlo

# About the agent:
# on-policy, first visit, optimistic initial values, epsilon-greedy policy

extends "res://Agents/LearningAgent.gd"

class Step:
    var state_action
    var score
    var time
    var epsilon_action

    func _init(sa, s, t, e):
        state_action = sa
        score = s
        time = t
        epsilon_action = e


var prev_sec = OS.get_ticks_msec() / 1000.0 

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
            
# 6 actions
# prob max_action x (1/6)
# prob of every other action y (5/6)
# if <= EPSILON
    var epsilon_action = false
    var curr_sec = OS.get_ticks_msec()
    if curr_sec - prev_sec >= 0.05:
        prev_sec = curr_sec
        epsilon_action = rand.randf_range(0,1) < EPSILON
        if epsilon_action:
            while true:
                var rand_action = ACTIONS[rand.randi_range(0,len(ACTIONS) - 1)]            
                if last_action != rand_action:
                    last_action = rand_action
                    break
    
    # remember relevant infromation
    last_state = state
    episode_steps.append(Step.new(
        get_state_action(last_state, last_action), score, OS.get_ticks_msec() / 1000.0,
        epsilon_action))

    return last_action

# initialize
func init(actions, read, write, filename, curr_n, debug):
    return init_agent('MonteCarlo', actions, read, write, filename, curr_n, debug)
   
# reset  
func start_game():
    start()

# update
func end_game(final_score, final_sec):
    if DEBUG:
        var n_steps = len(episode_steps)
        var s = "last actions: "
        for i in range(max(n_steps - 7, 0), n_steps):
            var step = episode_steps[i]
            if step.epsilon_action:
                s += "*"
            s += String(step.state_action) + " "
        print(s)

    var G = 0
    episode_steps.append(Step.new("", final_score, final_sec, false))
    
    for i in range(len(episode_steps) - 2,-1,-1):
        var curr_step = episode_steps[i]
        var next_step = episode_steps[i+1]
        var R = (next_step.score - curr_step.score)
        
        G =  pow(GAMMA,next_step.time - curr_step.time) * (R + G)
            
        # since we are using the first visit approach,
        # we only need the first occurrence  of this state_action
        if is_first_occurrence (curr_step.state_action, i):
            total_return[curr_step.state_action] += G
            visits[curr_step.state_action] += 1
            
    epsilon_update()

# write
func save(write):
    ad_write('MonteCarlo', write)

func Q(state, action):
    var state_action = get_state_action(state, action)
    if not (state_action in total_return):
        total_return[state_action] = INITIAL_OPTIMISTIC_VALUE
        visits[state_action] = 1
    return total_return[state_action] / visits[state_action]


func is_first_occurrence (state_action, index):
    for i in range(len(episode_steps)):
        var step = episode_steps[i]
        if step.state_action == state_action:
            return i == index
