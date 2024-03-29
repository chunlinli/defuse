import os
import numpy as np
import pandas as pd
from defuse.utils import count_accuracy
from notears.nonlinear import notears_nonlinear, NotearsMLP
import torch
torch.set_default_dtype(torch.double)

dims = [30, 100, ]
n = 500
graph_types = ['random', 'hub', ]
num_simulations = 50

results = {'p': [], 'graph': [], 'n': [],
           'sim': [], 'method': [],
           'fdr': [], 'fpr': [], 'tpr': [], 'shd': [], }

# create results directory
path = "simulation/results/"
isExist = os.path.exists(path)
if not isExist:
    os.makedirs(path)
    print(f'{path} is created')
else:
    print(f'{path} is existed')

for graph_type in graph_types:
    for d in dims:
        A = pd.read_csv(
            f'simulation/data/{graph_type}_{d}_A.csv', header=None).to_numpy()
        for sim in range(num_simulations):
            X = pd.read_csv(
                f'simulation/data/{graph_type}_{d}_X{sim}.csv', header=None).to_numpy()
            
            model = NotearsMLP(dims=[d, 10, 1], bias=True)
            A_est = notears_nonlinear(model, X, lambda1=0.1, lambda2=0.1)
            result = count_accuracy(A, A_est != 0)
            
            results['p'].append(d)
            results['graph'].append(graph_type)
            results['n'].append(n)
            results['sim'].append(sim)
            results['method'].append('notears')
            results['fdr'].append(result['fdr'])
            results['tpr'].append(result['tpr'])
            results['fpr'].append(result['fpr'])
            results['shd'].append(result['shd'])
            df = pd.DataFrame(results)
            df.to_csv(f'simulation/results/notears_results.csv', index=False)

print('done')
