class_name Random

var rand = RandomNumberGenerator.new()
    
func move():
   return [rand.randi_range(-1, 1), rand.randi_range(0, 1)]
