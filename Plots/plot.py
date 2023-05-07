from pathlib import Path
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

command_outputs_path = '../Game/Command_outputs/'

class Group:
    def __init__(self, name, scores, env, filename):
        self.name = name
        self.data = [0] * len(scores)
        self.env = env
        self.filename = filename
        self.count = 0
        self.win_score = -1

class AgentGroup:
    def __init__(self, name, scores, env, filename):
        self.name = name
        self.env = env
        self.filename = filename
        self.MC = Group('MC.' + name, scores, env, filename)
        self.S = Group('scores.' + name, scores, env, filename)
        self.QL = Group('QL.' + name, scores, env, filename)
        self.ES = Group('ES.' + name, scores, env, filename)
        self.DQL = Group('DQL.' + name, scores, env, filename)

def parse_state(state):
    state = state.split(',')
    return ('(' + state[0][1:] + ', ' + state[2][:-1] + ')', int(state[1]) )

'''
    calculates which move we will choose for each possible state for the TD agents
'''
def TD_calc(ad_data):
    result = {}
    curr_state_max = -1
    curr_move = ''
    last_state = ''
    for param, state_move in ad_data.items():
        # for this agent the parameter is calculated
        param = float(param)

        if state_move[0] != last_state and last_state != '':
            result[parse_state(last_state)] = MOVES_MAP[curr_move]
            curr_state_max = -1

        if curr_state_max < param:
            curr_state_max = param
            curr_move = state_move[1]

        last_state = state_move[0]

    result[parse_state(last_state)] = MOVES_MAP[curr_move]

    return result

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

# each row of the ad_data should be in the form of:
# [dist,rot,obstacle]_[movement,shooting]:parameters_for_specific_agent
def get_table(ad_data, agent):
    # ad_data (list of lines from agent_databases file) into:
    # dict ('parameters_for_specific_agent': [ '[dist,rot,obstacle]', '[movement,shooting]' ])
    ad_data = [line.split(':') for line in ad_data]

    if agent == 'DoubleQ_learning':
        ad_data = dict((line[1] if line[1] > line[2] else line[2], line[0].split('_')) for line in ad_data)
    else:
        ad_data = dict((line[1], line[0].split('_')) for line in ad_data)
    
    # resulting datastructure: dict { ((dist, 'obstacle'), rot) : MOVES_MAP value }
    chosen_moves = {}
    # get the move the agent would choose based on the agent we are using
    match agent:
        case 'MonteCarlo':
            chosen_moves = monte_carlo_calc(ad_data)
        case 'SARSA':
            chosen_moves = TD_calc(ad_data)
        case 'QLearning':
            chosen_moves = TD_calc(ad_data)
        case 'ExpectedSARSA':
            chosen_moves = TD_calc(ad_data)
        case 'DoubleQLearning':
            chosen_moves = TD_calc(ad_data)
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
                cell.append('_')
        cell_text.append(cell)

    return (cell_text, row_labels, col_labels)

def plotOption1(window, co_data, ad_data, agent, filename):
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

    # text above the plot
    spaces = '    '
    plt.figtext(x=0.02, y=0.95, s='Winning rate: ' + win_rate + spaces + 'Previous games: ' + num_of_prev_games+ spaces + 'Agent: ' + agent)
    agentSpecParam ='='.join(','.join(filename.split(',')[1:5]).split('=')[1:]).split(',')
    eps = agentSpecParam[0].split('=')[1]
    finalEps = agentSpecParam[1].split('=')[1]
    gam = agentSpecParam[2].split('=')[1]
    initOptVal = agentSpecParam[3].split('=')[1][:-1]
    plt.figtext(x=0.02, y=0.91, s='ε: ' + eps + spaces + 'Final-ε: ' + finalEps + spaces + 'γ: ' + gam + spaces + 'Initial optimistic value: ' + initOptVal)

    plt.xlabel('Episodes')
    plt.ylabel('Scores')
    
    ax.table(   cellText=ad_data[0],
                cellLoc='center',
                rowLabels=ad_data[1],
                rowLoc='center',
                colLabels=ad_data[2], 
                colLoc='center',
                loc='bottom',
                bbox=[0, -0.5 - (len(ad_data[1]) + 1) * 0.025, 1, 0.3 + (len(ad_data[1]) + 1) * 0.025])

def option1(window):
    f = open('Plots_log/option1.txt', 'w')
    total_plots = 0
    new_plots = 0
    existing_plots = 0
    error_plots = 0
    # files have the same names in both folders
    for filename in os.listdir(command_outputs_path):
        # filename format: f_c1_c2.txt
        # c1 = agent_databases counter
        # c2 = command_outputs counter
        filename = filename[:-4]
        f.write('----------------------------' + '\n')
        f.write('filename: ' + filename + '\n')
        total_plots += 1
        try:
            split_filename = filename.split('_')
            filename = split_filename[0]
            co_ver = split_filename[1]
            co_f = open(command_outputs_path + filename + '_' + co_ver + '.txt', 'r')
            co_f = co_f.read().strip().split('\n')
            index = co_f.index('')
            co_data = co_f[:index]
            agent = filename.split(',')[0].split('=')[1]
           
            ad_data = get_table(co_f[index+1:], agent)

            # create path so that we can sort out the plots nicely
            env = filename[filename.find('env'):]
            env = 'all' if '=all' in env else env[5:env.find(']')]
            if env == 'Bugs,Tokens,Traps,Viruses':
                env = 'all'
                
            path = 'Plots/option1/' + env + '/win=' + str(window) + '/' + agent + '/'
            if not os.path.isdir(path):
                os.makedirs(path)
            
            full_plot_filename = path + filename + '_' + co_ver + '.png'
            if os.path.isfile(full_plot_filename):
                existing_plots += 1
                f.write('EXISTING PLOT' + '\n')
                continue
            
            plotOption1(window, co_data, ad_data, agent, filename)

            plt.savefig(full_plot_filename, bbox_inches='tight', pad_inches=0.2, dpi=100)
            new_plots += 1
        except Exception:
            error_plots += 1
            f.write('FILE ERROR' + '\n')
            
    f.write('----------------------------' + '\n')
    f.write('Total plots: ' + str(total_plots) + '\n')
    f.write('New plots: ' + str(new_plots) + '\n')
    f.write('Existing plots: ' + str(existing_plots) + '\n')
    f.write('Error plots: ' + str(error_plots) + '\n')
    f.write('----------------------------' + '\n')
    f.close()

def plotOption2(window, scores, agent, filename, winning_score):
    avg_score = [sum(scores) / len(scores)] * len(scores)
    scores = [np.mean(scores[i:i + window]) if i <= len(scores) -
              window else np.mean(scores[i:]) for i in range(len(scores))]
    episodes = [i for i in range(1, len(scores)+1)]

    _, ax = plt.subplots()

    ax.plot(episodes, scores, '-c', label='Data')
    ax.plot(episodes, avg_score, '--r', label='Mean')
    if winning_score != -1:
        ax.plot(episodes, winning_score, '--b', label='Winning score')
    ax.legend(loc='upper right')

    # text above the plot
    spaces = '    '
    plt.figtext(x=0.02, y=0.95, s='Agent: ' + agent)
    agentSpecParam ='='.join(','.join(filename.split(',')[1:5]).split('=')[1:]).split(',')
    eps = agentSpecParam[0].split('=')[1]
    finalEps = agentSpecParam[1].split('=')[1]
    gam = agentSpecParam[2].split('=')[1]
    initOptVal = agentSpecParam[3].split('=')[1][:-1]
    plt.figtext(x=0.02, y=0.91, s='ε: ' + eps + spaces + 'Final-ε: ' + finalEps + spaces + 'γ: ' + gam + spaces + 'Initial optimistic value: ' + initOptVal)

    plt.xlabel('Episodes')
    plt.ylabel('Scores')

def option2(window):
    f = open('Plots_log/option2.txt', 'w')
    groups = {}
    # files have the same names in both folders
    for filename in os.listdir(command_outputs_path):
        # filename format: f_c1_c2.txt
        # c1 = agent_databases counter
        # c2 = command_outputs counter
        filename = filename[:-4]
        f.write('----------------------------' + '\n')
        f.write('filename: ' + filename + '\n')
        commonParam = ''
        try:
            split_filename = filename.split('_')
            filename = split_filename[0]
            co_ver = split_filename[1]

            co_f = open(command_outputs_path + filename + '_' + co_ver + '.txt', 'r')
            co_f = co_f.read().strip().split('\n')
            index = co_f.index('')
            co_data = co_f[:index]
            scores = [float(i) for i in co_data[:-4]]

            # create path so that we can sort out the plots nicely
            env = filename[filename.find('env'):]
            env = 'all' if '=all' in env else env[5:env.find(']')]
            if env == 'Bugs,Tokens,Traps,Viruses':
                env = 'all'

            filenameFragments = filename.split(',')

            commonParam = str(filenameFragments[0:9])
            if not commonParam in groups.keys():
                groups[commonParam] = Group(commonParam, scores, env, filename)

            groups[commonParam].data = [x + y for x, y in zip(scores, groups[commonParam].data)]
            groups[commonParam].count += 1
            if groups[commonParam].win_score == -1:
                groups[commonParam].win_score = [float(co_data[-4].split()[1])] * len(scores) if co_data[-4].split()[1] != 'unknown' else -1
                
        except Exception:
            f.write('FILE ERROR: remove or replace incorrect files for the group: ' + str(commonParam) + '\n')
            continue

    for key in groups.keys():
        groups[key].data = [x / groups[key].count for x in groups[key].data]
        agent = groups[key].filename.split(',')[0].split('=')[1]
        
        plotOption2(window, groups[key].data, agent, groups[key].filename, groups[key].win_score)

        # create path so that we can sort out the plots nicely
        path = 'Plots/option2/' + groups[key].env + '/win=' + str(window) + '/' + agent + '/'
        if not os.path.isdir(path):
            os.makedirs(path)
        plt.savefig(path + key + '.png', bbox_inches='tight', pad_inches=0.2, dpi=100)
    
    f.close()

def plotOption3(window, MC, S, QL, ES, DQL, filename):
    MC = [np.mean(MC[i:i + window]) if i <= len(MC) -
              window else np.mean(MC[i:]) for i in range(len(MC))]
    S = [np.mean(S[i:i + window]) if i <= len(S) -
              window else np.mean(S[i:]) for i in range(len(S))]
    QL = [np.mean(QL[i:i + window]) if i <= len(QL) -
              window else np.mean(QL[i:]) for i in range(len(QL))]
    ES = [np.mean(ES[i:i + window]) if i <= len(ES) -
              window else np.mean(ES[i:]) for i in range(len(ES))]
    DQL = [np.mean(DQL[i:i + window]) if i <= len(DQL) -
              window else np.mean(DQL[i:]) for i in range(len(DQL))]

    _, ax = plt.subplots()

    plt.plot(MC, color='red', label='MonteCarlo')
    plt.plot(S, color='green', label='SARSA')
    plt.plot(QL, color='blue', label='QLearning')
    plt.plot(ES, color='cyan', label='ExpectedSARSA')
    plt.plot(DQL, color='magenta', label='DoubleQLearning')

    plt.legend()

    # text above the plot
    spaces = '    '
    agentSpecParam ='='.join(','.join(filename.split(',')[1:5]).split('=')[1:]).split(',')
    eps = agentSpecParam[0].split('=')[1]
    finalEps = agentSpecParam[1].split('=')[1]
    gam = agentSpecParam[2].split('=')[1]
    initOptVal = agentSpecParam[3].split('=')[1][:-1]
    plt.figtext(x=0.02, y=0.91, s='ε: ' + eps + spaces + 'Final-ε: ' + finalEps + spaces + 'γ: ' + gam + spaces + 'Initial optimistic value: ' + initOptVal)

    plt.xlabel('Episodes')
    plt.ylabel('Scores')

def option3(window):
    f = open('Plots_log/option3.txt', 'w')
    groups = {}
    # files have the same names in both folders
    for filename in os.listdir(command_outputs_path):
        # filename format: f_c1_c2.txt
        # c1 = agent_databases counter
        # c2 = command_outputs counter
        filename = filename[:-4]
        f.write('----------------------------' + '\n')
        f.write('filename: ' + filename + '\n')
        commonParam = ''
        try:
            split_filename = filename.split('_')
            filename = split_filename[0]
            co_ver = split_filename[1]
            co_f = open(command_outputs_path + filename + '_' + co_ver + '.txt', 'r')
            co_f = co_f.read().strip().split('\n')
            index = co_f.index('')
            co_data = co_f[:index]
            scores = [float(i) for i in co_data[:-4]]

            # create path so that we can sort out the plots nicely
            env = filename[filename.find('env'):]
            env = 'all' if '=all' in env else env[5:env.find(']')]
            if env == 'Bugs,Tokens,Traps,Viruses':
                env = 'all'

            filenameFragments = filename.split(',')
            agent = filenameFragments[0].split('=')[1]

            commonParam = str(filenameFragments[1:9])
            if not commonParam in groups.keys():
                groups[commonParam] = AgentGroup(commonParam, scores, env, filename)

            match(agent):
                case 'MonteCarlo':
                    groups[commonParam].MC.data = [x + y for x, y in zip(scores, groups[commonParam].MC.data)]
                    groups[commonParam].MC.count += 1
                case 'SARSA':
                    groups[commonParam].S.data = [x + y for x, y in zip(scores, groups[commonParam].S.data)]
                    groups[commonParam].S.count += 1
                case 'QLearning':
                    groups[commonParam].QL.data = [x + y for x, y in zip(scores, groups[commonParam].QL.data)]
                    groups[commonParam].QL.count += 1
                case 'ExpectedSARSA':
                    groups[commonParam].ES.data = [x + y for x, y in zip(scores, groups[commonParam].ES.data)]
                    groups[commonParam].ES.count += 1
                case 'DoubleQLearning':
                    groups[commonParam].DQL.data = [x + y for x, y in zip(scores, groups[commonParam].DQL.data)]
                    groups[commonParam].DQL.count += 1
                case _:
                    raise Exception
                
        except Exception:
            f.write('FILE ERROR: remove or replace incorrect files for the group: ' + str(commonParam) + '\n')
            continue
        
    for key in groups.keys():
        groups[key].MC.data = [x / groups[key].MC.count for x in groups[key].MC.data]
        groups[key].S.data = [x / groups[key].S.count for x in groups[key].S.data]
        groups[key].QL.data = [x / groups[key].QL.count for x in groups[key].QL.data]
        groups[key].ES.data = [x / groups[key].ES.count for x in groups[key].ES.data]
        groups[key].DQL.data = [x / groups[key].DQL.count for x in groups[key].DQL.data]
        
        plotOption3(window, groups[key].MC.data, groups[key].S.data, groups[key].QL.data,
                     groups[key].ES.data, groups[key].DQL.data, groups[key].filename)
        
        # create path so that we can sort out the plots nicely
        path = 'Plots/option3/' + groups[key].env + '/win=' + str(window) + '/'
        if not os.path.isdir(path):
            os.makedirs(path)
        plt.savefig(path + key + '.png', bbox_inches='tight', pad_inches=0.2, dpi=100)
    
    f.close()


'''
loop through all the files from Command_outputs, plot the data and save the plot (unless it already exists)
'''
def main(option, window):
    directory = 'Plots_log/'
    if not os.path.isdir(directory):
        os.makedirs(directory)

    match (option):
        case 1:
            option1(window)
        case 2:
            option2(window)
        case 3:
            option3(window)
        case _:
            print('Invalid arguments')
            return


def getDescription():
    try:
        with open('plottingDescription.txt', 'r') as f:
            return f.read()
    except FileNotFoundError:
        print('File not found')
        raise SystemExit
    except PermissionError:
        print('Permission denied')
        raise SystemExit
    
if __name__ == '__main__':
    # read description content from the txt file
    description = getDescription()

    if len(sys.argv) == 1 or (len(sys.argv) == 2 and sys.argv[1] == '--description'):
        print(description)
        raise SystemExit
    
    # take average of window size scores (default 10)
    window = 10
    option = 1
    if len(sys.argv) == 2 or len(sys.argv) == 3:
        for arg in sys.argv[1:]:
            temp = arg[2:].split('=')
            if temp[0] == 'option':
                option = int(temp[1])
            elif temp[0] == 'window':
                window = int(temp[1])
            else:
                print('Invalid arguments')
                exit 
    elif len(sys.argv) > 3:
        print('Invalid number of arguments')
        exit

    main(option, window)
