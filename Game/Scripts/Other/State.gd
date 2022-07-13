extends Label

var state = [0,0,0]

func update_state(dist,rot,type):
    state = [dist, rot, type]
    text = "[d>%d,r=%d,t=%s]" % state

func get_state():
    return state
