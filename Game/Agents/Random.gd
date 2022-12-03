class_name Random

# IMPORTANT!
# agent's function move returns a list of 2 elements:
# - first element indicates the movement : -1 - left, 0 - just go forward, 1 - right
# - second element decides if Hans should shoot : 1 - yes, 0 - no

var rand = RandomNumberGenerator.new()

# all possible actions
var ACTIONS = []

# move and remember
func move(_state, _score):
    var result = [rand.randi_range(-1, 1), rand.randi_range(0, 1)]
    
    if result in ACTIONS:
        return result
        
    return [result[0], 0]

# initialize
func init(actions, _read, _write, _filename, _curr_n, _debug):
    ACTIONS = actions
    return true

# reset
func start_game(_eval):
    pass

# update
func end_game(_final_score, _final_time):
    pass

#write
func save(_write):
    pass

func get_and_set_agent_specific_parameters(_agent_specific_param):
    return []

func get_n():
    return '0'
