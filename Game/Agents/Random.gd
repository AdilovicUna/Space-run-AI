extends Node

var tunnels
var hans
var rand = RandomNumberGenerator.new()

func _init(main):
    tunnels = main.get_node_or_null("Tunnels")
    hans = main.get_node_or_null("Hans") 
    
func move():
    #rotates all children of "traps"
    if rand.randi_range(0,1) == 0:
        var tunnel = tunnels.get_child(hans.get_current_tunnel())
        tunnel.rotate_object_local(Vector3.RIGHT,-PI/90)
    else:
        var tunnel = tunnels.get_child(hans.get_current_tunnel())
        tunnel.rotate_object_local(Vector3.LEFT,-PI/90)
    if not hans == null: # if it is not instanced we can't call the function       
        hans.switch_animation()
