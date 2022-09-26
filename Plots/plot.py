import matplotlib.pyplot as plt
import numpy as np
import os
from pathlib import Path

# - first element indicates the movement : -1 - left, 0 - Forward, 1 - right
# - second element decides if Hans should shoot : 1 - yes, 0 - no
MOVES_MAP = {
    '[-1,0]': '←', '[0,0]': '↑', '[1,0]': '→',
    '[-1,1]': '←*', '[0,1]': '↑*', '[1,1]': '→*'
}

'''
loop through all the files from Command_outputs, plot the data and save the plot (unless it already exists)
'''


def main():
    command_outputs_path = '../Game/Command_outputs/'
    agent_databases_path = '../Game/Agent_databases/'

    # files have the same names in both folders
    for filename in os.listdir(command_outputs_path):
        filename = filename[:-4]
        
        co_f = open(command_outputs_path + filename + '.txt', 'r')
        co_data = co_f.read().strip().split('\n')

        agent = filename.split(',')[0].split('=')[1]
        ad_f = open(agent_databases_path + filename + '.txt', 'r')
        ad_data = get_table(ad_f.read().strip().split('\n')[1:], agent)
        print("_____________________________________________________________________________________________")
        #plot(co_data, ad_data)
        #plt.savefig(filename + '.png')


def plot(co_data, ad_data):
    window = 10  # take average of window size scores
    scores = [float(i) for i in co_data[:-3]]
    scores = [np.mean(scores[i:i + window]) if i <= len(scores) -
              window else np.mean(scores[i:]) for i in range(len(scores))]
    episodes = [i for i in range(1, len(scores)+1)]
    win_rate = co_data[-3]
    avg_score = [float(co_data[-2])] * len(scores)
    num_of_prev_games = co_data[-1]

    _, ax = plt.subplots()

    ax.plot(episodes, scores, label='Data')
    ax.plot(episodes, avg_score, label='Mean', linestyle='--')
    ax.legend(loc='upper right')

    plt.figtext(x=0.02, y=0.04, s='Winning rate: ' + win_rate)
    plt.figtext(x=0.02, y=0.01, s='Previous games: ' + num_of_prev_games)

    plt.xlabel('Episodes')
    plt.ylabel('Scores')

# each row of the ad_data should be in the form of:
# [dist,rot,obstacle]_[movement,shooting]:parameters_for_specific_agent


def get_table(ad_data, agent):
    # ad_data (list of lines from agent_databases file) into:
    # dict ('parameters_for_specific_agent': [ '[dist,rot,obstacle]', '[movement,shooting]' ])
    ad_data = [line.split(':') for line in ad_data]
    ad_data = dict((line[1], line[0].split('_')) for line in ad_data)
    
    # resulting datastructure: dict { ((dist, 'obstacle'), rot) : MOVES_MAP value }
    chosen_moves = {}
    # get the move the agent would choose based on the agent we are using
    match agent:
        case 'MonteCarlo':
            chosen_moves = monte_carlo_calc(ad_data)
        case _:
            raise Exception('Agent ' + agent + ' does not exist')


    cell_text = []    
    col_labels = []
    row_labels = []
    
    for key in chosen_moves.keys():
        if not key[0] in row_labels:
            row_labels.append(key[0])
        if not key[1] in col_labels:
            col_labels.append(key[1])

    row_labels.sort()
    print('row_labels: ', row_labels)
    col_labels.sort()
    print('col_labels: ', col_labels)
    for row in row_labels:
        cell = []
        for col in col_labels:
            if (row,col) in chosen_moves:
                cell.append(chosen_moves[row,col])
            else:
                cell.append("_")
        cell_text.append(cell)

    print(col_labels)
    for i in range(len(row_labels)):
        print(row_labels[i], " ", cell_text[i])       

    return

'''
    calculates which move we will choose for each possible state for the Monte Carlo agent
'''
def monte_carlo_calc(ad_data):
    result = {}
    curr_state_max = -1
    curr_move = ''
    last_state = ''
    for param, state_move in ad_data.items():
        # for this agent we only need to devide the parameters
        param = eval(param)

        if state_move[0] != last_state and last_state != '':
            result[parse_state(last_state)] = MOVES_MAP[curr_move]
            curr_state_max = -1

        if curr_state_max < param:
            curr_state_max = param
            curr_move = state_move[1]

        last_state = state_move[0]

    result[parse_state(last_state)] = MOVES_MAP[curr_move]

    print(result)
    return result

def parse_state(state):
    state = state.split(',')
    return ((int(state[0][1:]),state[2][:-1]), int(state[1]) )

main()
