import numpy as np
from sklearn.metrics import pairwise_distances


def feature_scores(y, z, x=None):
    '''
    Input: 
        y: n by 1 array.
        z: n by q array.
        x: n by p array.
    Output:
        scores: q array.
    '''
    n, q = len(y), z.shape[-1]
    sort_idx = np.argsort(y.squeeze())
    z = z[sort_idx, :]
    scores = np.zeros(q)
    if x is not None:
        x = x[sort_idx, :]
        dmat_x = pairwise_distances(x)
        dmat_x[range(n), range(n)] = float('inf')
        for j in range(q):
            dmat_j = pairwise_distances(np.concatenate(
                (z[:, j].reshape(n, 1), x), axis=1))
            dmat_j[range(n), range(n)] = float('inf')
            num, den = 0.0, 0.0
            for r in range(n):
                r_N = np.argmin(dmat_x[r, :])
                r_M = np.argmin(dmat_j[r, :])
                num = num + min(r, r_M) - min(r, r_N)
                den = den + r - min(r, r_N)
            scores[j] = num / den
    else:
        for j in range(q):
            dmat_j = pairwise_distances(z[:, j].reshape(n, 1))
            dmat_j[range(n), range(n)] = float('inf')
            num, den = 0.0, 0.0
            for r in range(n):
                r_M = np.argmin(dmat_j[r, :])
                num = num + n * min(r, r_M) - (n - r)**2
                den = den + (n - r) * r
            scores[j] = num / den
    return scores


def feature_list(y, x):
    '''
    Input: 
        y: n by 1 array.
        x: n by d array.
    Output:
        features: array
    '''
    d = x.shape[-1]
    features, idx = np.zeros(d, dtype=bool), np.array(range(d))
    while not features.all():
        if features.any():
            scores = feature_scores(y=y, z=x[:, ~features], x=x[:, features])
        else:
            scores = feature_scores(y=y, z=x)
        if np.max(scores) < 0.05:
            break
        features[idx[~features][np.argmax(scores)]] = True
    return features


def feature_vector_score(y, z):
    '''
    Input: 
        y: n by 1 array.
        z: n by q array.
    Output:
        score, float.
    '''
    n, sort_idx = len(y), np.argsort(y.squeeze())
    z = z[sort_idx, :]
    num, den = 0.0, 0.0

    dist_mat = pairwise_distances(z)
    dist_mat[range(n), range(n)] = float('inf')
    for r in range(n):
        r_M = np.argmin(dist_mat[r, :])
        num = num + n * min(r, r_M) - (n - r)**2
        den = den + (n - r) * r

    return num / den


def main():
    import scipy
    n, d = 500, 100
    X = np.random.normal(scale=2, size=d*n).reshape(n, d)

    def exponentiated_quadratic(xa, xb):
        sq_norm = - 0.5 * \
            scipy.spatial.distance.cdist(xa, xb, 'sqeuclidean')
        return np.exp(sq_norm)

    function_type = 'cos'
    if function_type == 'GP':
        X0 = X[:, 0].reshape(n, 1)
        S = exponentiated_quadratic(X0, X0)
        y = 2 * np.random.multivariate_normal(
            mean=np.zeros(n), cov=S, size=1) + np.random.normal(size=n)
        y = y.reshape(n, 1)
    else:
        ys = 3 * np.cos(X[:, 0] * X[:, 1]) + 2 * \
            np.sin(X[:, 0]) + 2 * np.cos(X[:, 2])
        ys = ys.reshape(1, n)
        y = ys + np.random.normal(size=n)
        y = y.reshape(n, 1)
    print(np.nonzero(feature_list(y=y, x=X)))


if __name__ == '__main__':
    main()
