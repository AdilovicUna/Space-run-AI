class_name Random

var main
var tunnels
var hans
var rand = RandomNumberGenerator.new()

func _init(arg):
    self.main = arg
    tunnels = main.tunnels
    
func move():
   return [rand.randi_range(-1, 1), rand.randi_range(0, 1)]
