
import matplotlib.pyplot as plt 
import numpy as np

filename = "agent_MonteCarlo_tunnel_1_sorted_env_[Triangles]_shooting_True_actions_[[-1,0],[0,0],[1,0]]_dists_4_rots_12"
f = open("../Game/Command_outputs/" + filename + ".txt", "r")
data = f.read().strip().split('\n')

window = 10
scores = [float(i) for i in data[:-1]]
scores = [np.mean(scores[i:i + window]) if i <= len(scores) - window else np.mean(scores[i:]) for i in range(len(scores))]
episodes = [i for i in range(1,len(scores)+1)]
avg_score = [float(data[-1])] * len(scores)

fig,ax = plt.subplots()cd 

data_line = ax.plot(episodes, scores, label='Data')
mean_line = ax.plot(episodes, avg_score, label='Mean', linestyle='--')
legend = ax.legend(loc='upper right')

plt.xlabel('Episodes') 
plt.ylabel('Scores') 
    
plt.title(filename) 

plt.show()