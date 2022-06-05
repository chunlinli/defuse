import defuse.utils
import os
import numpy as np

path = "simulation/data/"
isExist = os.path.exists(path)
if not isExist:
    os.makedirs(path)
    print(f'{path} is created')
else:
    print(f'{path} is existed')

dims = [30, 100]
n = 500
graph_types = ['random', 'hub']

for graph_type in graph_types:
    for d in dims:
        defuse.utils.set_random_seed(1110)
        A = defuse.utils.simulate_dag(d, graph_type=graph_type)
        np.savetxt(f'{path}{graph_type}_{d}_A.csv', A, delimiter=',')
        _, cf, fn = defuse.utils.simulate_data(A, n, 'poly-trig')

        for i in range(50):
            X, _, _ = defuse.utils.simulate_data(A=A, n=n, sem_type='poly-trig', coefficient=cf, functions=fn)
            np.savetxt(f'{path}{graph_type}_{d}_X{i}.csv', X, delimiter=',')