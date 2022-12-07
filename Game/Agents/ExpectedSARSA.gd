class_name ExpectedSARSA
# About the agent:
# on-policy, optimistic initial values, epsilon-greedy policy

extends "res://Agents/TDAgent.gd"

func get_update(state, new_action, best_action):
    var sum = 0.0
    var probability = EPSILON / len(ACTIONS)
    if best_action == new_action:
        probability = 1 - EPSILON + EPSILON/len(ACTIONS)
        
    for action in ACTIONS:
        sum += probability * Q(state,action)
    return sum
