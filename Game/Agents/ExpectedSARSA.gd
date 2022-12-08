class_name ExpectedSARSA
# About the agent:
# on-policy, optimistic initial values, epsilon-greedy policy

extends "res://Agents/TDAgent.gd"

func get_update(state, _new_action, best_action):
    var sum = 0.0 
    for action in ACTIONS:
        var probability = EPSILON / len(ACTIONS)
        if action == best_action:
            probability += 1 - EPSILON
        sum += probability * Q(state,action)
    return sum
