
import matplotlib.pyplot as plt 
import numpy as np
import os
from pathlib import Path

'''
loop through all the files from Command_outputs, plot the data and save the plot (unless it already exists)
'''
def main():
    path = "../Game/Command_outputs/"
    for filename in os.listdir(path):
        filename = filename[:-4]
        f = open("../Game/Command_outputs/" + filename + ".txt", "r")
        data = f.read().strip().split('\n')
        plot(data)
        plt.savefig(filename + ".png")

      
def plot(data):
    window = 10
    scores = [float(i) for i in data[:-1]]
    scores = [np.mean(scores[i:i + window]) if i <= len(scores) - window else np.mean(scores[i:]) for i in range(len(scores))]
    episodes = [i for i in range(1,len(scores)+1)]
    avg_score = [float(data[-1])] * len(scores)

    _,ax = plt.subplots()

    ax.plot(episodes, scores, label='Data')
    ax.plot(episodes, avg_score, label='Mean', linestyle='--')
    ax.legend(loc='upper right')

    plt.xlabel('Episodes') 
    plt.ylabel('Scores') 

main()
