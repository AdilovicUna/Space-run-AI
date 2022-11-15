from email.policy import default
from genericpath import exists
import subprocess
import sys
from turtle import goto


def build_filename(agent, agent_spec_param, level, env, shooting, dists, rots):
    sorted_env = sorted(env)
    sorted_agent_spec_param = sorted(agent_spec_param)

    if sorted_env == None:
        sorted_env = "all"

    command = ["agent=" + str(agent), "agentSpecParam=" + str(sorted_agent_spec_param), "level=" + str(level), "env=" + str(sorted_env),
               "shooting=" + str(shooting == 'enabled'), "dists=" + str(dists), "rots=" + str(rots)]

    return ','.join(command).replace(' ', '').replace('\'', '')


def run_with_one_env(database, agent, agent_spec_param, n, env, shooting, level, path, curr_env,
                    dists_from, dists_to, rots_from, rots_to, win_rate_minimum):

    dists = dists_from
    rots = rots_from

    win_rate = 0
    command_outputs_path = '../Game/Command_outputs/'

    agent_spec_param_str = ','.join(agent_spec_param)

    while True:
        if (win_rate >= win_rate_minimum or 
            (dists == dists_to and rots == rots_to)):
            return

        command = ['godot', '--no-window', '--fixed-fps', '1', '--disable-render-loop',
                   'database=' + database,
                   'level=' + str(level),
                   'agent=' + agent + ':' + agent_spec_param_str,
                   'n=' + str(n),
                   'env=' + env,
                   'rots=' + str(rots),
                   'dists=' + str(dists),
                   'shooting=' + shooting]
        subprocess.run(command, cwd=path)

        filename = build_filename(
            agent,  agent_spec_param, level, curr_env, shooting, dists, rots)
        co_f = open(command_outputs_path + filename + '.txt', 'r')
        co_data = co_f.read().strip().split('\n')
        win_rate = co_data[-3].split()[1].split('/')
        win_rate = int(win_rate[0]) / int(win_rate[1])

        if rots == rots_to:
            dists += 1
            rots = rots_from
        else:
            rots += 1

def find_minimum_param(agent, level, curr_env,shooting):
    result_d = 1
    result_r = 6
    command_outputs_path = '../Game/Command_outputs/'
    for env in curr_env:
        dists = 10
        rots = 100
        for d in range(dists, 0, -1):
            for r in range(rots, 0, -1):
                filename = build_filename(agent, level, [env], 
                                            shooting, d, r)
                if exists(command_outputs_path + filename + '.txt'):
                    result_d = max(result_d, d)
                    result_r = max(result_r, r)
                    break
            else:
                continue
            break

    return [result_d, result_r]

def run(curr_env, games_per_env, 
        len_traps, len_bugs, len_viruses, len_tokens,
        database, agent, agent_spec_param, level, path,
        dists_from, dists_to, rots_from, rots_to, win_rate_minimum, subsets):
    
    # n = (games_per_env * len(curr_env) + 
    #     games_per_env * len_traps * int('traps' in curr_env) + 
    #     games_per_env * len_bugs * int('bugs' in curr_env) + 
    #     games_per_env * len_viruses * int('viruses' in curr_env) + 
    #     games_per_env * len_tokens * int('tokens' in curr_env) +
    #     games_per_env * int(dists_to > 4) + 
    #     games_per_env * int(rots_to > 12))

    n=1

    env = ','.join(curr_env)

    if subsets:
        dists_from, rots_from = find_minimum_param(agent, level, curr_env,'disabled')
    
    run_with_one_env(database, agent, agent_spec_param, n, env,
                        'disabled', level, path, curr_env,
                         dists_from, dists_to, rots_from, rots_to, win_rate_minimum)

    if 'bugs' in curr_env or 'viruses' in curr_env:
        if subsets:
            dists_from, rots_from = find_minimum_param(agent, level, curr_env,'enabled')
        run_with_one_env(database, agent, agent_spec_param, n, env,
                            'enabled', level, path, curr_env,
                            dists_from, dists_to, rots_from, rots_to, win_rate_minimum)

def main(all_env, subsets, dists_from, dists_to, rots_from, rots_to, 
            games_per_env, win_rate_minimum,
            gam, eps, initOptVal):
    len_traps = 10
    len_bugs = 3
    len_viruses = 2
    len_tokens = 1
    
    env_powerset = [[]]

    agent = 'MonteCarlo'
    database = 'write'
    level = 1

    agent_spec_param =["gam=" + str(gam), "eps=" + str(eps), "initOptVal=" + str(initOptVal)]

    path = '../Game'

    if subsets:
        special_env = ['traps', 'bugs', 'viruses', 'tokens']
        if 'traps' in all_env:
            all_env = [env for env in all_env if env in special_env]

        for i in all_env:
            for j in range(len(env_powerset)):
                curr_env = env_powerset[j]+[i]
                print('curr_env: ', curr_env)

                env_powerset += [curr_env]
                if env_powerset == []:
                    return
                
                run(curr_env, games_per_env,
                    len_traps, len_bugs, len_viruses, len_tokens,
                    database, agent, agent_spec_param, level, path, 
                    dists_from, dists_to, rots_from, rots_to, win_rate_minimum, subsets)
    else:
        for i in all_env:
            curr_env = [i]
            run(curr_env, games_per_env,
                len_traps, len_bugs, len_viruses, len_tokens,
                database, agent, agent_spec_param, level, path,
                dists_from, dists_to, rots_from, rots_to, win_rate_minimum, subsets)

if __name__ == '__main__':

    # arg format: env=I,MovingI,bugs,... subsets=False (or True)
    #             dists=1,4 rots=6,12 win_rate_minimum=0.3 games_per_env=250

    #all_env = ['traps', 'bugs', 'viruses', 'tokens', 'I', 'O', 'MovingI', 'X', 'Walls', 'Hex', 'HexO', 'Balls', 'Triangles', 'HalfHex']
    #all_env = ['I', 'O', 'MovingI', 'X', 'Walls', 'Hex', 'HexO', 'Balls', 'Triangles', 'HalfHex']
    all_env = ['I', 'O', 'MovingI', 'X', 'Walls', 'Hex', 'Triangles']
    #all_env = ['HexO', 'Balls', 'HalfHex']
    
    # indicates if the program should test only individual elements of the all_env
    # or all of the subsets (powerset)
    subsets = True

    games_per_env = 250

    dists_from = 1
    dists_to = 4

    rots_from = 6
    rots_to = 24

    gam = 1
    eps = 0
    initOptVal = 100

    win_rate_minimum = 0.3

    for i in range(1,len(sys.argv)):
        i = sys.argv[i]
        temp = i.split('=')
        match temp[0]:
            case "env":
                all_env = temp[1].split(',')
            case "subsets":
                subsets = temp[1] == 'True'
            case "dists":
                d = temp[1].split(',')
                dists_from = int(d[0])
                dists_to = int(d[1])
            case "rots":
                r = temp[1].split(',')
                rots_from = int(r[0])
                rots_to = int(r[1])
            case "win_rate_minimum":
                win_rate_minimum = int(temp[1])
            case "games_per_env":
                games_per_env = int(temp[1])
            case "gam":
                gam = float(temp[1])
            case "eps":
                eps = float(temp[1])
            case "initOptVal":
                initOptVal = float(temp[1])
            case _:
                print("Invalid arguments")
                exit 
            
    main(all_env, subsets, dists_from, dists_to, rots_from, rots_to, games_per_env, win_rate_minimum, gam, eps, initOptVal)
