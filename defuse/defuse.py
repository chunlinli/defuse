import torch
import numpy as np
from sklearn.linear_model import LassoLarsIC
from scipy.stats import anderson
from defuse.feature import feature_list, feature_vector_score
from defuse.trainer import DefuseTrainer
from defuse.defusenet import DefuseNet

class Defuse:
    def __init__(self, model_config=None, train_config=None):

        self.model_config = model_config if model_config else {
            'hidden_struct': [50],
            'model_type': 'mlp',
            'activation': 'sigmoid',
            'alpha': 0.01,
            'fit_measure': 'anderson',
            'threshold': 0.05
        }
        self.train_config = train_config if train_config else {
            'n_epochs': [500, 3500],
            'penalty_type': ['l1', 'tlp'],
            'penalty_param': [1e-4, 5e-2]
        }

    def _test_goodness_of_fit(self, Z, de_ind):
        '''
        Test goodness of fit for the descendants.

        Args:
        Z: [n, d] numpy array. Residual data.
        de_ind: descendants integer array.

        Returns:
        an_ind: ancestors integer array.
        '''

        an_ind, stats = [], []
        sd = Z.std(axis=0)
        # maybe write anderson test to a function

        for j in de_ind:
            #q0, q1 = np.quantile(Z[:, j], [0, 1])

            z_test = Z[:, j]
            #z_test = z_test[(Z[:, j] > q0) & (Z[:, j] < q1)]
            z_test = (z_test - z_test.mean()) / sd[j]

            if self.model_config['fit_measure'] == 'anderson':
                stat, crit, _ = anderson(z_test, 'norm')
                stats.append(stat)
                if stat < crit[3]:
                    an_ind.append(j)
            else:
                raise ValueError('Unknown goodness of fit measure.')

        # confirm goodness of fit
        if len(an_ind) > 1:
            an_sd = sd[an_ind]
            sort_an = np.array(an_ind)[np.argsort(an_sd)]

            for j in range(1,len(sort_an)):
                m = LassoLarsIC('bic', normalize=False).fit(
                    Z[:, sort_an[:j]], Z[:, sort_an[j]])
                residuals = Z[:, sort_an[j]] - m.predict(Z[:, sort_an[:j]])
                #score = feature_scores(y=residuals, z=Z[:, sort_an[:j]])
                score = feature_vector_score(y=residuals, z=Z[:, sort_an[:j]])
                #score = feature_vector_score(y=residuals, z=Z[:, sort_an[np.nonzero(m.coef_)]])

                # under-fit
                # TODO: check if this is the right way to check
                if (score > 2*self.model_config['threshold']).any():
                    an_ind.remove(sort_an[j])

        if len(an_ind) == 0:
            an_ind.append(de_ind[np.argmin(sd[de_ind])])
        return an_ind

    def _select_variables(self, X, Z, an_ind, j):
        '''
        Args:
        X: numpy array
        Z: numpy array
        an_ind: numpy integer array
        j: int

        Returns:
        confounders: numpy integer array
        features: numpy integer array
        '''

        m = LassoLarsIC('bic', normalize=False).fit(Z[:, an_ind], X[:, j])
        residuals = X[:, j] - m.predict(Z[:, an_ind])

        confounders = an_ind[np.nonzero(m.coef_)]
        features = an_ind[np.nonzero(
            feature_list(y=residuals, x=X[:, an_ind]))]

        return confounders, features, residuals

    def _train_defuse_model(self, X, Z, an_ind, de_ind):
        '''
        X: [n, len(an)] numpy array
        Z: [n, len(an)] numpy array
        an_ind: ancestors integer array
        de_ind: descendants integer array 
        '''

        parents, residuals = {}, {}

        for j in de_ind:
            confounders, features, res = self._select_variables(
                X, Z, an_ind, j)

            input0_dim, input1_dim = len(features), len(confounders)
            if input0_dim > 0:
                x = torch.from_numpy(X[:, features]).float()
            else:
                parents.update({j: np.array([], dtype=int)})
                residuals.update({j: res})
                continue
            if input1_dim > 0:
                z = torch.from_numpy(Z[:, confounders]).float()
            else:
                z = torch.from_numpy(Z[:, features]).float()
            y = torch.from_numpy(X[:, [j]]).float()

            model = DefuseNet(
                model_type=self.model_config['model_type'],
                dims=[[input0_dim] +
                      self.model_config['hidden_struct'] + [1], [input1_dim]],
                activation=self.model_config['activation'])
            trainer = DefuseTrainer(
                train_config=self.train_config, defuse_net=model)
            trainer.train(x, z, y)

            thresh = np.sqrt(
                self.model_config['hidden_struct'][0]) * self.model_config['threshold']

            features_mask = torch.norm(
                model.feaure_weight, p="fro", dim=0) > thresh
            parents.update({j: features[features_mask.numpy()]})

            y_pred = trainer.predict(x, z)
            residuals.update({j: (y - y_pred).numpy()})

        return residuals, parents

    def _from_dict_to_matrix(self, pa, d):
        '''
        Convert adjcactivity list to adjacency matrix.
        Args:
        pa: adjacency dictionary.

        Returns:
        A_mat: [d, d] numpy array. Adjacency matrix.
        '''
        A_mat = np.zeros([d, d], dtype=int)
        for j in pa.keys():
            A_mat[pa[j], j] = 1

        return A_mat

    def fit(self, X, verbose=False):
        '''
        Fit a defuse model to the data.
        X: [n, d] numpy array. Data.
        verbose: bool. Whether to print the adjacency list.

        Returns:
        A_mat: [d, d] numpy array. Adjacency matrix.
        '''
        pa = {}
        Z = X.copy()
        d = X.shape[-1]
        an_ind, de_ind = np.arange(0), np.arange(d)

        while True:

            an_ind = np.union1d(an_ind, self._test_goodness_of_fit(Z, de_ind))
            if len(an_ind) == d:
                break
            else:
                de_ind = np.setdiff1d(np.arange(d), an_ind)
                if verbose:
                    print(len(an_ind), len(de_ind))
                    print(pa)
                residuals, parents = self._train_defuse_model(
                    X, Z, an_ind, de_ind)
                pa.update(parents)
                for j, res_j in residuals.items():
                    Z[:, [j]] = res_j.reshape(-1, 1)

        A_mat = self._from_dict_to_matrix(pa, d)
        return A_mat, Z
