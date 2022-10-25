import subprocess
import sys


def build_filename(agent, level, env, shooting, dists, rots):
    sorted_env = sorted(env)

    if sorted_env == None:
        sorted_env = "all"

    command = ["agent=" + str(agent), "level=" + str(level), "env=" + str(sorted_env),
               "shooting=" + str(shooting == 'enabled'), "dists=" + str(dists), "rots=" + str(rots)]

    return ','.join(command).replace(' ', '').replace('\'', '')


def run_with_one_env(database, agent, n, env, shooting, level, path, curr_env):
    dists = 1
    rots = 6
    win_rate = 0

    command_outputs_path = '../Game/Command_outputs/'

    while True:
        if win_rate >= 0.3 or (dists == 4 and rots == 24):
            break

        command = ['godot', '--no-window', '--fixed-fps', '1', '--disable-render-loop',
                   'database=' + database,
                   'level=' + str(level),
                   'agent=' + agent,
                   'n=' + str(n),
                   'env=' + env,
                   'rots=' + str(rots),
                   'dists=' + str(dists),
                   'shooting=' + shooting]

        subprocess.run(command, cwd=path)

        filename = build_filename(
            agent, level, curr_env, shooting, dists, rots)
        co_f = open(command_outputs_path + filename + '.txt', 'r')
        co_data = co_f.read().strip().split('\n')
        win_rate = co_data[-3].split()[1]
        win_rate = int(win_rate[0]) / int(win_rate[2])

        if rots == 24:
            dists += 1
            rots = 6
        else:
            rots += 1


def main(all_env):
    special_env = ['I', 'bugs', 'viruses']
    len_traps = 10
    len_bugs = 3
    len_viruses = 2
    len_tokens = 1
    
    # 250 per env in case dists and rots get very big
    games_per_env = 250

    if 'traps' in all_env:
        all_env = [env for env in all_env if env in special_env]
    
    env_powerset = [[]]

    agent = 'MonteCarlo'
    database = 'write'
    level = 1

    path = '../Game'

    for i in all_env:
        for j in range(len(env_powerset)):
            curr_env = env_powerset[j]+[i]
            env_powerset += [curr_env]

            if env_powerset == []:
                continue
            
            n = (games_per_env * len(curr_env) + 
                games_per_env * len_traps * int('traps' in curr_env) + 
                games_per_env * len_bugs * int('bugs' in curr_env) + 
                games_per_env * len_viruses * int('viruses' in curr_env) + 
                games_per_env * len_tokens * int('tokens' in curr_env))

            env = ','.join(curr_env)

            run_with_one_env(database, agent, n, env,
                             'disabled', level, path, curr_env)

            if 'bugs' in curr_env or 'viruses' in curr_env:
                run_with_one_env(database, agent, n, env,
                                 'enabled', level, path, curr_env)

if __name__ == '__main__':

    # arg format: env=I,MovingI,bugs ...

    all_env = ['traps', 'bugs', 'viruses', 'tokens', 'I', 'O', 'MovingI', 'X', 'Walls', 'Hex', 'HexO', 'Balls', 'Triangles', 'HalfHex']

    if len(sys.argv) == 2:
        temp = sys.argv[1].split('=')

        if temp[0] == "env":
            all_env = temp[1].split(',')
        else:
            print("Invalid arguments")
            exit 

    elif len(sys.argv) > 2:
        print("Invalid number of arguments")
        exit
    
    main(all_env)
