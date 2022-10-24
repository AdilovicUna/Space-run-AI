import subprocess


def build_filename(agent, level, env, shooting, dists, rots):
    sorted_env = sorted(env)

    if sorted_env == None:
        sorted_env = "all"

    command = ["agent=" + str(agent), "level=" + str(level), "env=" + str(sorted_env), 
                            "shooting=" + str(shooting), "dists=" + str(dists), "rots=" + str(rots)]

    return ','.join(command).replace(' ','')

def run_with_one_env(database, agent, n, env, shooting, level, path, curr_env):
    dists = 1
    rots = 6
    win_rate = 0

    command_outputs_path = '../Game/Command_outputs/'

    while True:
        if win_rate >= 0.3 or (dists == 4 and rots == 30):
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

        subprocess.Popen(command, cwd=path)
        
        # filename = build_filename(agent,level,curr_env,shooting,dists,rots)
        # co_f = open(command_outputs_path + filename + '.txt', 'r')
        # co_data = co_f.read().strip().split('\n')
        # win_rate = co_data[-3].split()[1]
        # print(win_rate)

        break


def main():
    #all_env = ['traps', 'bugs', 'viruses', 'tokens', 'I', 'O', 'MovingI', 'X', 'Walls', 'Hex', 'HexO', 'Balls', 'Triangles', 'HalfHex']
    all_env = ['I', 'O']
    env_powerset = [[]]

    agent = 'MonteCarlo'
    database = 'write'
    level = 1

    command = []
    path = '../Game'

    subsets = [[]]

    for i in all_env:
        for j in range(len(env_powerset)):
            curr_env = env_powerset[j]+[i]
            env_powerset += [curr_env]

            if env_powerset == []:
                continue

            n = 3 * len(curr_env)
            env = ','.join(curr_env)

           
            run_with_one_env(database, agent, n, env, 'disabled', level, path, curr_env)

            if 'bugs' in curr_env or 'viruses' in curr_env:
                run_with_one_env(database, agent, n, env, 'enabled', level, path, curr_env)


if __name__ == '__main__':
    main()
