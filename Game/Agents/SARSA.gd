class_name SARSA
# About the agent:
# on-policy, optimistic initial values, epsilon-greedy policy

extends "res://Agents/TDAgent.gd"

func get_update(state, new_action, _best_action):
    return q[get_state_action(state, new_action)]
