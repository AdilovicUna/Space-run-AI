class_name ExpectedSARSA
# About the agent:
# on-policy, optimistic initial values, epsilon-greedy policy

extends "res://Agents/TDAgents.gd"

func get_update(state, new_action, _best_action):
    var sum = 0.0
    var probability = 1.0 / len(ACTIONS)
    for action in ACTIONS:
        sum += probability * Q(state,action)
    return String(sum)
