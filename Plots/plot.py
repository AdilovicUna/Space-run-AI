from pydoc import ispath
import sys
import matplotlib.pyplot as plt
import numpy as np
import os

# - first element indicates the movement : -1 - left, 0 - Forward, 1 - right
# - second element decides if Hans should shoot : 1 - yes, 0 - no
MOVES_MAP = {
    '[-1,0]': '←', '[0,0]': '↑', '[1,0]': '→',
    '[-1,1]': '←*', '[0,1]': '↑*', '[1,1]': '→*'
}

'''
loop through all the files from Command_outputs, plot the data and save the plot (unless it already exists)
'''


def main(window):
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
        plot(window, co_data, ad_data)


        # create path so that we can sort out the plots nicely
        env = filename[filename.find('env'):]
        env = 'all' if '=all' in env else env[5:env.find(']')]

        path = 'plots/' + env + '/win=' + str(window) + '/no_disc,iov=100.00/'
        if not os.path.isdir(path):
            os.makedirs(path)


        plt.savefig(path + filename + '.png',bbox_inches='tight', pad_inches=0.2, dpi=100)


def plot(window, co_data, ad_data):
    scores = [float(i) for i in co_data[:-4]]
    scores = [np.mean(scores[i:i + window]) if i <= len(scores) -
              window else np.mean(scores[i:]) for i in range(len(scores))]
    episodes = [i for i in range(1, len(scores)+1)]
    winning_score = [float(co_data[-4].split()[1])] * len(scores) if co_data[-4].split()[1] != 'unknown' else -1
    win_rate = co_data[-3].split()[1]
    avg_score = [float(co_data[-2].split()[1])] * len(scores)
    num_of_prev_games = co_data[-1].split()[1]

    _, ax = plt.subplots()

    ax.plot(episodes, scores, '-c', label='Data')
    ax.plot(episodes, avg_score, '--r', label='Mean')
    if winning_score != -1:
        ax.plot(episodes, winning_score, '--b', label='Winning score')
    ax.legend(loc='upper right')

    plt.figtext(x=0.02, y=0.95, s='Winning rate: ' + win_rate)
    plt.figtext(x=0.02, y=0.91, s='Previous games: ' + num_of_prev_games)

    plt.xlabel('Episodes')
    plt.ylabel('Scores')

    ax.table(  cellText=ad_data[0],
                cellLoc='center',
                rowLabels=ad_data[1],
                rowLoc='center',
                colLabels=ad_data[2], 
                colLoc='center',
                loc='bottom',
                bbox=[0, -0.5 - (len(ad_data[1]) + 1) * 0.025, 1, 0.3 + (len(ad_data[1]) + 1) * 0.025])
   
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
    col_labels.sort()

    for row in row_labels:
        cell = []
        for col in col_labels:
            if (row,col) in chosen_moves:
                cell.append(chosen_moves[row,col])
            else:
                cell.append("_")
        cell_text.append(cell)

    return (cell_text, row_labels, col_labels)

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

    return result

def parse_state(state):
    state = state.split(',')
    return ('(' + state[0][1:] + ', ' + state[2][:-1] + ')', int(state[1]) )

if __name__ == "__main__":

    # take average of window size scores (default 10)
    window = 10
    if len(sys.argv) == 2:
        temp = sys.argv[1].split('=')
        if temp[0] == "window":
            window = int(temp[1])
        else:
            print("Invalid arguments")
            exit 
    elif len(sys.argv) > 2:
        print("Invalid number of arguments")
        exit
    
    main(window)
