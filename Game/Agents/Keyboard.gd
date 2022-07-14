class_name Keyboard
    
func move(_state, _score):
    var result = [0,0]
    if Input.is_action_pressed("right"):
        result[0] = 1
    elif Input.is_action_pressed("left"):
        result[0] = -1
        
    if Input.is_action_pressed("shoot"):
        result[1] = 1
        
    return result

func start_game():
    pass

func end_game(_final_score):
    pass
