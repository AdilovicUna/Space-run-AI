import subprocess
import sys
import os

# min distance for any env is assumed to be dists=1
rotsDict = {
    'O': 13,
    'X': 11,
    'I': 6,
    'MovingI': 6,
    'Triangles': 6,
    'Hex': 22,
    'HexO': 7,
    'HalfHex': 6,
    'Walls': 22,
    'Balls': 15,
    'Traps': 22,

    'Worm': 6, 
    'LadybugFlying': 6, 
    'LadybugWalking': 6, 
    'Bugs': 6,

    'Rotavirus': 6, 
    'Bacteriophage': 6,
    'Viruses': 6
}

POSSIBLE_TRAPS = ['I','O', 'MovingI', 'X', 'Walls', 
                        'Hex', 'HexO', 'Balls', 'Triangles', 'HalfHex']
POSSIBLE_BUGS = ['Worm', 'LadybugFlying', 'LadybugWalking']
POSSIBLE_VIRUSES = ['Rotavirus', 'Bacteriophage']


def build_filename(agent, agent_spec_param, level, env, shooting, dists, rots, agent_seed_val):
    sorted_env = sorted(env)
    sorted_agent_spec_param = sorted(agent_spec_param)

    if sorted_env == None:
        sorted_env = 'all'

    command = ['agent=' + str(agent), 'agentSpecParam=' + str(sorted_agent_spec_param), 'level=' + str(level), 'env=' + str(sorted_env),
               'shooting=' + str(shooting == 'enabled'), 'dists=' + str(dists), 'rots=' + str(rots),  'agentSeedVal=' + str(agent_seed_val)]

    return ','.join(command).replace(' ', '').replace('\'', '')


def run(path, command, filename):
    print('command: ', command)

    directory = 'Tests_output/'
    if not os.path.isdir(directory):
        os.makedirs(directory)

    # write results in a file so that they can be inspected later
    with open('Tests_output/' + filename + '.txt', 'w') as f:
        subprocess.run(command, cwd=path, stdout=f,
                       stderr=subprocess.STDOUT, text=True)


def main(n, m, env, agent, shooting, level, database, ceval, debug,
         gam, eps, epsFinal, initOptVal, stoppingPoint, individual_env):

    path = '../Game'
    dists = 1
    # note: for sub-options while loops are used to loop
    #       because range() does not accept floats

    # loop seeds
    for seed in range(m):
        # loop agents
        for one_agent in agent:
            # loop shooting
            for one_shooting in shooting:
                gam_value = round(gam[0], 2)
                # loop gamma
                while gam_value < gam[1]:
                    eps_value = round(eps[0], 2)
                    # loop epsilon
                    while eps_value < eps[1]:
                        epsFinal_value = round(epsFinal[0], 5)
                        # loop final epsilon
                        while epsFinal_value < epsFinal[1]:
                            initOptVal_value = round(initOptVal[0], 1)
                            # loop initial optimistic value
                            while initOptVal_value < initOptVal[1]:
                                agent_spec_param = ['gam=' + '{:.2f}'.format(round(gam_value, 2)), 
                                                    'eps=' + '{:.2f}'.format(round(eps_value, 2)), 
                                                    'epsFinal=' + '{:.5f}'.format(round(epsFinal_value, 5)), 
                                                    'initOptVal=' + '{:.1f}'.format(round(initOptVal_value, 1))]
                                command = ['godot', '--no-window', '--fixed-fps', '1', '--disable-render-loop',
                                           'level=' + str(level),
                                           'n=' + str(n),
                                           'agentSeedVal=' + str(seed),
                                           'stoppingPoint=' +
                                           str(stoppingPoint),
                                           'dists=' + str(dists),
                                           'agent=' + one_agent + ':' +
                                           ','.join(agent_spec_param),
                                           'shooting=' + one_shooting,
                                           'debug=' + debug,
                                           'ceval=' + ceval,
                                           'database=' + database]
                                if individual_env:
                                    # loop environment
                                    for e in env:
                                        rots = rotsDict[e]
                                        command.append('env=' + e)
                                        command.append('rots=' + str(rots))
                                        filename = build_filename(
                                            one_agent, agent_spec_param, level, [e], one_shooting, dists, rots, seed)
                                        run(path, command, filename)
                                else:  # only 1 environment
                                    rots = minRots(env)
                                    command.append('env=' + ','.join(env))
                                    command.append('rots=' + str(rots))
                                    filename = build_filename(
                                        one_agent, agent_spec_param, level, env, one_shooting, dists, rots, seed)
                                    run(path, command, filename)

                                initOptVal_value += initOptVal[2]
                            epsFinal_value += epsFinal[2]
                        eps_value += eps[2]
                    gam_value += gam[2]


def getSubOptVals(param):
    param = param[1:-1].split(',')
    return [float(param[0]), float(param[1]), float(param[2])]


def getDescription():
    try:
        with open('testingDescription.txt', 'r') as f:
            return f.read()
    except FileNotFoundError:
        print('File not found')
        raise SystemExit
    except PermissionError:
        print('Permission denied')
        raise SystemExit


def minRots(env):
    temp_env = [e for e in env
                if e != 'Traps' and e != 'Bugs' and e != 'Viruses' and e != 'Tokens']
    return min([rotsDict[e]] for e in temp_env)[0]


if __name__ == '__main__':
    # read description content from the txt file
    description = getDescription()

    if len(sys.argv) == 2 and sys.argv[1] == '-description':
        print(description)
        raise SystemExit

    # default values for args:
    n = 100
    m = 10
    env = ['Traps', 'Bugs', 'Viruses', 'Tokens']  # all
    agent = ['MonteCarlo']
    shooting = 'disabled'
    level = 1
    database = 'write'
    ceval = 'true'  # Space-run indicates bool vals with lowercase
    debug = 'false'
    stoppingPoint = 10

    gam = [1.0, 2.0, 1.0]  # essentially there is only 1 gam value
    eps = [0.2, 0.3, 0.1]
    epsFinal = [0.0001, 0.0002, 0.0001]
    initOptVal = [100.0, 200.0, 100.0]

    all_traps = False
    all_bugs = False
    all_viruses = False
    all_agents = False
    all_shooting = False

    # read all args and overwrite default values if needed
    try:
        print('sys.argv: ', sys.argv)
        for i in range(1, len(sys.argv)):
            i = sys.argv[i][2:]  # [2:] to remove --
            temp = i.split('=')
            match temp[0]:
                case 'n':
                    n = int(temp[1])
                case 'm':
                    m = int(temp[1])
                case 'level':
                    level = int(temp[1])
                case 'stoppingPoint':
                    stoppingPoint = int(temp[1])
                case 'env':
                    env = [a for a in temp[1][1:-1].split(',')]
                case 'agent':
                    agent = [a for a in temp[1][1:-1].split(',')]
                case 'shooting':
                    shooting = temp[1]
                case 'database':
                    database = temp[1]
                case 'ceval':
                    ceval = temp[1]
                case 'debug':
                    debug = temp[1]

                case 'gam':
                    gam = getSubOptVals(temp[1])
                case 'eps':
                    eps = getSubOptVals(temp[1])
                case 'epsFinal':
                    epsFinal = getSubOptVals(temp[1])
                case 'initOptVal':
                    initOptVal = getSubOptVals(temp[1])

                case 'all_traps':
                    all_traps = True
                case 'all_bugs':
                    all_bugs = True
                case 'all_viruses':
                    all_viruses = True
                case 'all_agents':
                    all_agents = True
                case 'all_shooting':
                    all_shooting = True
                case _:
                    print(f'Invalid argument {i}')
                    print('Run with `-description` parameter for more infromation')
                    raise SystemExit
    except Exception:
        print('Invalid argument')
        print('Run with `-description` parameter for more infromation')
        raise SystemExit

    # customize and overwrite immutable variables if needed
    # env
    individual_env = all_traps or all_bugs or all_viruses
    if individual_env:
        env = []
        if all_traps:
            env.extend(POSSIBLE_TRAPS)
        if all_bugs:
            env.extend(POSSIBLE_BUGS)
        if all_viruses:
            env.extend(POSSIBLE_VIRUSES)
    # agent
    if all_agents:
        agent = ['MonteCarlo', 'SARSA', 'QLearning',
                 'ExpectedSARSA', 'DoubleQLearning']
    # shooting
    if all_shooting and (all_bugs or all_viruses):
        shooting = ['enabled', 'disabled']
    else:
        shooting = [shooting] 

    main(n, m, env, agent, shooting, level, database, ceval, debug,
         gam, eps, epsFinal, initOptVal, stoppingPoint, individual_env)
