extends Label

var level = 0

func update_level():
    level += 1
    text = "Level %s" % level

func get_level():
    return level
    
func set_level(starting_level):
    level = starting_level
