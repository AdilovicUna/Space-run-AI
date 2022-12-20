class_name QLearning
# About the agent:
# on-policy, optimistic initial values, epsilon-greedy policy

extends "res://Agents/TDAgent.gd"

func get_update(state, _new_action, best_action):
    return q[get_state_action(state, best_action)]