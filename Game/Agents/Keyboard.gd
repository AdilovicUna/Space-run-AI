class_name Keyboard

# IMPORTANT!
# agent's function move returns a list of 2 elements:
# - first element indicates the movement : -1 - left, 0 - just go forward, 1 - right
# - second element decides if Hans should shoot : 1 - yes, 0 - no

func move(_state, _score):
    var result = [0,0]
    if Input.is_action_pressed("right"):
        result[0] = 1
    elif Input.is_action_pressed("left"):
        result[0] = -1
        
    if Input.is_action_pressed("shoot"):
        result[1] = 1
        
    return result

func start_game(_dists, _rots, _types):
    pass

func end_game(_final_score):
    pass
