from pathlib import Path
import sys
import matplotlib.pyplot as plt
import numpy as np
import os
import re

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
    MC = []
    S = []
    QL = []
    ES = []
    DQL = []

    MC_count = 0
    S_count = 0
    QL_count = 0
    ES_count = 0
    DQL_count = 0
    c = 0
    # files have the same names in both folders
    for filename in os.listdir(command_outputs_path):
        print(filename)

        filename = filename[:-4]
        try:
            split_filename = filename.split('_')
            filename = split_filename[0]
            co_ver = split_filename[1]
            co_f = open(command_outputs_path + filename + '_' + co_ver + '.txt', 'r')
            co_f = co_f.read().strip().split('\n')
            co_data = co_f[:50]
            co_data = [float(a) for a in co_data]
            if len(co_data) != 50:
                continue

            agent = filename.split(',')[0].split('=')[1]
            print('agent: ', agent)
            eps = filename[filename.find('eps'):filename.find('epsFinal')]
            eps = float(eps[eps.find('=') + 1:eps.find(',')])
            print('eps: ', eps)
            initOptVal = filename[filename.find('initOptVal'):filename.find(']')]
            initOptVal = float(initOptVal[initOptVal.find('=') + 1:])
            print('initOptVal: ', initOptVal)
            env = filename[filename.find('env'):]
            env = 'all' if '=all' in env else env[5:env.find(']')]
            print('env: ', env)

            if (env in ['Viruses']):
                c += 1
                match agent:
                    case 'MonteCarlo':
                        if MC == []:
                            MC = co_data
                        else:
                            MC = [x + y for x, y in zip(MC, co_data)]
                        MC_count += 1
                    case 'SARSA':
                        if S == []:
                            S = co_data
                        else:
                            S = [x + y for x, y in zip(S, co_data)]
                        S_count += 1
                    case 'QLearning':
                        print('*************************************************************')
                        if QL == []:
                            QL = co_data
                        else:
                            QL = [x + y for x, y in zip(QL, co_data)]
                        QL_count += 1
                    case 'ExpectedSARSA':
                        if ES == []:
                            ES = co_data
                        else:
                            ES = [x + y for x, y in zip(ES, co_data)]
                        ES_count += 1
                    case 'DoubleQLearning':
                        if DQL == []:
                            DQL = co_data
                        else:
                            DQL = [x + y for x, y in zip(DQL, co_data)]
                        DQL_count += 1
                    case _:
                        raise Exception('Agent ' + agent + ' does not exist')
        except Exception:
            print("FILE ERROR")
    print(c)
    window = 10

    MC = [x / MC_count for x in MC]
    S = [x / S_count for x in S]
    QL = [x / QL_count for x in QL]
    ES = [x / ES_count for x in ES]
    DQL = [x / DQL_count for x in DQL]

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

    plt.plot(MC, label='MonteCarlo')
    plt.plot(S, label='SARSA')
    plt.plot(QL, label='QLearning')
    plt.plot(ES, label='ExpectedSARSA')
    plt.plot(DQL, label='DoubleQLearning')

    plt.legend()

    if not os.path.isdir('plots/combo/'):
        os.makedirs('plots/combo/')

    plt.savefig('plots/combo/env=' + 'viruses' +'.png', bbox_inches='tight', pad_inches=0.2, dpi=100)

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
