extends Node

var all_agents = ["Static", "Random"]

var n = 100
var agent = "Static"
var scores = []

var paramSet = false

func set_param(param):
    if not paramSet:
        paramSet = true
        # modify options based on args
        for key in param:
            if key == "n":
                n = int(param[key])
            if key== "agent":
                agent = param[key]
    
        #check if everything is valid
        if n < 0 or not agent in all_agents:
            return false   
    
func get_n():
    return n

func decrement_n():
    n -= 1
    return n

func get_agent():
    return agent

func add_score(score):
    scores.append(score)

func get_avg_score():
    var sum = 0.0
    for score in scores:
         sum += score
    return sum / scores.size()
