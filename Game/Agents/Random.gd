class_name Random

var rand = RandomNumberGenerator.new()
    
func move(_state, _score):
   return [rand.randi_range(-1, 1), rand.randi_range(0, 1)]

func start_game():
    pass

func end_game(_final_score):
    pass
