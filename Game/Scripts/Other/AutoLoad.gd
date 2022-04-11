extends Node

var all_agents = ["Static", "Random"]

var n = 100
var agent = "Static"
var scores = []

var paramSet = false

func setParam(param):
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
    
func getN():
    return n

func decrementN():
    n -= 1
    return n

func getAgent():
    return agent

func addScore(score):
    scores.append(score)

func getAvgScore():
    var sum = 0.0
    for score in scores:
         sum += score
    return sum / scores.size()
