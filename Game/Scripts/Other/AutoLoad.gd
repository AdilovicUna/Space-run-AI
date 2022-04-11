extends Node

var all_agents = ["None", "Static", "Random"]

var n = 100
var agent = "None"
var scores_sum = 0.0
var scores_count = 0
var last_score = 0.0

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
    scores_count += 1
    last_score = score
    scores_sum += score

func get_last_score():
    return last_score

func get_scores_count():
    return scores_count

func get_avg_score():
    return scores_sum / scores_count
