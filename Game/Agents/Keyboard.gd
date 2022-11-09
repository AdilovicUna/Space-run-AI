class_name Keyboard

# IMPORTANT!
# agent's function move returns a list of 2 elements:
# - first element indicates the movement : -1 - left, 0 - just go forward, 1 - right
# - second element decides if Hans should shoot : 1 - yes, 0 - no

# NOTE: actions are constant for the keyboard agent since we don't want to change the behavior of the game

# move and remember
func move(_state, _score):
    var result = [0,0]
    if Input.is_action_pressed("right"):
        result[0] = 1
    elif Input.is_action_pressed("left"):
        result[0] = -1
        
    if Input.is_action_pressed("shoot"):
        result[1] = 1

    return result

# initialize
func init(_actions, _read, _filename, _curr_n, _agent_specific_param):
    return true

# reset
func start_game():
    pass

# update
func end_game(_final_score):
    pass

#write
func save(_write):
    pass
    
func get_n():
    return '0'
