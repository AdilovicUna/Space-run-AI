class_name Random

var rand = RandomNumberGenerator.new()
    
func move(state, score):
   return [rand.randi_range(-1, 1), rand.randi_range(0, 1)]

func start_game():
    pass

func end_game(final_score):
    pass
