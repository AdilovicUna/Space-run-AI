class_name Static

# IMPORTANT!
# agent's function move returns a list of 2 elements:
# - first element indicates the movement : -1 - left, 0 - just go forward, 1 - right
# - second element decides if Hans should shoot : 1 - yes, 0 - no

var rand = RandomNumberGenerator.new()

# move and remember
func move(_state, _score):
   return [0,0]

# initialize
func init(_actions, _read, _filename, _curr_n, _agent_specific_param):
    return true

# reset
func start_game():
    pass

# update
func end_game(_final_score, _final_time):
    pass

#write
func save(_write):
    pass
    
func get_n():
    return '0'
