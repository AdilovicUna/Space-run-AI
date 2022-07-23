class_name Static

# IMPORTANT!
# agent's function move returns a list of 2 elements:
# - first element indicates the movement : -1 - left, 0 - just go forward, 1 - right
# - second element decides if Hans should shoot : 1 - yes, 0 - no

var rand = RandomNumberGenerator.new()

func move(_state, _score):
   return [0,0]

func start_game(_dists, _rots, _types):
    pass

func end_game(_final_score):
    pass
