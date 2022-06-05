import numpy as np
import random
from pandas import array

from torch import dtype
import igraph as ig


def set_random_seed(seed):
    random.seed(seed)
    np.random.seed(seed)


def simulate_dag(d, graph_type):
    """
    Simulate random DAG with some expected number of edges.

    Args:
        d (int): num of nodes
        graph_type (str): random, hub

    Returns:
        A (np.ndarray): [d, d] binary adjacency matrix of DAG
    """

    if graph_type == 'random':
        p = 1/d
        A = np.random.binomial(n=1, p=p, size=d*d).reshape(d, d)
        A = np.triu(A, k=1)

    elif graph_type == 'hub':
        
        # the first 1/3 nodes are connected to hubs, others are isolated

        A = np.zeros([d, d])
        A[0, 1:] = 1
    else:
        raise ValueError('Invalid graph type.')

    return A


def simulate_data(A, n, sem_type, covariance=None, coefficient=None, functions=None):
    """
    Simulate samples from nonlinear SEM.

    Args:
        A (np.ndarray): [d, d] binary adj matrix of DAG
        n (int): num of samples
        sem_type (str): poly-trig, additive-gp
        covariance (np.ndarray): scales of additive noise

    Returns:
        X (np.ndarray): [n, d] sample matrix
    """
    def simulate_latent_variables(n, d, covariance=None):
        """
        Simulate latent variables.
        Args:
            n (int): num of samples
            d (int): num of nodes
            covariance: [d, d] covariance matrix

        Returns:
            Z: [n, d] latent variables
        """

        # may need change
        if covariance is None:
            # covariance = np.zeros([d, d])
            # diag_mask = np.diag(np.ones(d, dtype=bool))
            # matrix_mask = np.ones([d, d], dtype=bool) * ~ diag_mask
            # covariance[np.tril(matrix_mask, k=1) * np.triu(matrix_mask, k=-1)] = 1
            # covariance[range(d), range(d)] = 2.5
            # covariance[-1,-1] = 1.5

            covariance = np.zeros([d, d])
            diag_mask = np.diag(np.ones(d, dtype=bool))
            matrix_mask = np.ones([d, d], dtype=bool) * ~ diag_mask
            offdiag = np.zeros(d-1)
            offdiag[[True if i % 2 == 0 else False for i in range(d-1)]] = 1.0
            covariance[np.tril(matrix_mask, k=1) *
                       np.triu(matrix_mask, k=0)] = offdiag
            covariance[range(d), range(d)] = 2
            covariance = np.maximum(covariance, covariance.transpose())

        else:
            assert d == covariance.shape[0] == covariance.shape[1]
        Z = np.random.multivariate_normal(
            mean=np.zeros(d), cov=covariance, size=n)
        return Z, covariance

    def simulate_single_equation(X, z, coefficient=None, functions=None):
        """
        X: [n, num of parents], 
        y: [n, 1]
        """

        pa_size = X.shape[1]
        if pa_size == 0:
            return z, np.array([]), np.array([])
        elif sem_type == 'poly-trig':
            if coefficient is None:
                func = np.random.choice(
                    [np.square, np.cos], size=pa_size)
                coefs = np.random.uniform(low=2.5, high=3, size=pa_size)
                coefs = coefs * np.random.choice([-1, 1], size=pa_size)
            else:
                func = functions
                coefs = coefficient
            y = sum([coefs[i] * func[i](X[:, [i]])
                    for i in range(pa_size)]) + z
        elif sem_type == 'additive-gp':
            from sklearn.gaussian_process import GaussianProcessRegressor
            gp = GaussianProcessRegressor()
            if coefficient is None:
                func = np.random.randint(0, 1e+6, size=pa_size)
                coefs = np.random.uniform(low=2.5, high=3, size=pa_size)
            else:
                func = functions
                coefs = coefficient
            y = sum([coefs[i] * gp.sample_y(X[:, [i]], random_state=func[i])
                     for i in range(pa_size)]) + z
        else:
            raise ValueError('Invalid structural equation type.')
        return y, coefs, func

    def parents(A, j):
        pa = np.nonzero(A[:, j])[0]
        return pa

    d = A.shape[0]
    Z, _ = simulate_latent_variables(n, d, covariance)
    X = np.zeros([n, d])
    coefs, func = {}, {}
    for j in range(d):
        pa = parents(A, j)
        if coefficient is None or functions is None:
            X[:, [j]], cf, fn = simulate_single_equation(X[:, pa], Z[:, [j]])
        else:
            X[:, [j]], cf, fn = simulate_single_equation(
                X[:, pa], Z[:, [j]], coefficient=coefficient[j], functions=functions[j])
        coefs.update({j: cf})
        func.update({j: fn})

    return X, coefs, func


def is_dag(W):
    G = ig.Graph.Weighted_Adjacency(W.tolist())
    return G.is_dag()


def count_accuracy(B_true, B_est):
    """Compute various accuracy metrics for B_est.

    true positive = predicted association exists in condition in correct direction
    reverse = predicted association exists in condition in opposite direction
    false positive = predicted association does not exist in condition

    Args:
        B_true (np.ndarray): [d, d] ground truth graph, {0, 1}
        B_est (np.ndarray): [d, d] estimate, {0, 1, -1}, -1 is undirected edge in CPDAG

    Returns:
        fdr: (reverse + false positive) / prediction positive
        tpr: (true positive) / condition positive
        fpr: (reverse + false positive) / condition negative
        shd: undirected extra + undirected missing + reverse
        nnz: prediction positive
    """
    if (B_est == -1).any():  # cpdag
        if not ((B_est == 0) | (B_est == 1) | (B_est == -1)).all():
            raise ValueError('B_est should take value in {0,1,-1}')
        if ((B_est == -1) & (B_est.T == -1)).any():
            raise ValueError('undirected edge should only appear once')
    else:  # dag
        if not ((B_est == 0) | (B_est == 1)).all():
            raise ValueError('B_est should take value in {0,1}')
        if not is_dag(B_est):
            raise ValueError('B_est should be a DAG')
    d = B_true.shape[0]
    # linear index of nonzeros
    pred_und = np.flatnonzero(B_est == -1)
    pred = np.flatnonzero(B_est == 1)
    cond = np.flatnonzero(B_true)
    cond_reversed = np.flatnonzero(B_true.T)
    cond_skeleton = np.concatenate([cond, cond_reversed])
    # true pos
    true_pos = np.intersect1d(pred, cond, assume_unique=True)
    # treat undirected edge favorably
    true_pos_und = np.intersect1d(pred_und, cond_skeleton, assume_unique=True)
    true_pos = np.concatenate([true_pos, true_pos_und])
    # false pos
    false_pos = np.setdiff1d(pred, cond_skeleton, assume_unique=True)
    false_pos_und = np.setdiff1d(pred_und, cond_skeleton, assume_unique=True)
    false_pos = np.concatenate([false_pos, false_pos_und])
    # reverse
    extra = np.setdiff1d(pred, cond, assume_unique=True)
    reverse = np.intersect1d(extra, cond_reversed, assume_unique=True)
    # compute ratio
    pred_size = len(pred) + len(pred_und)
    cond_neg_size = 0.5 * d * (d - 1) - len(cond)
    fdr = float(len(reverse) + len(false_pos)) / max(pred_size, 1)
    tpr = float(len(true_pos)) / max(len(cond), 1)
    fpr = float(len(reverse) + len(false_pos)) / max(cond_neg_size, 1)
    # structural hamming distance
    pred_lower = np.flatnonzero(np.tril(B_est + B_est.T))
    cond_lower = np.flatnonzero(np.tril(B_true + B_true.T))
    extra_lower = np.setdiff1d(pred_lower, cond_lower, assume_unique=True)
    missing_lower = np.setdiff1d(cond_lower, pred_lower, assume_unique=True)
    shd = len(extra_lower) + len(missing_lower) + len(reverse)
    return {'fdr': fdr, 'tpr': tpr, 'fpr': fpr, 'shd': shd, 'nnz': pred_size}


def main():

    set_random_seed(1117)

    d = 30
    n = 500
    A = simulate_dag(d, 'random')
    _, cf, fn = simulate_data(A, n, 'poly-trig')


    for i in range(50):
        X, _, _ = simulate_data(A=A, n=n, sem_type='poly-trig', coefficient=cf, functions=fn)
        np.savetxt('W_est.csv', W_est, delimiter=',')



if __name__ == '__main__':
    main()
