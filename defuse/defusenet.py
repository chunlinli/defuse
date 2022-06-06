import torch
import torch.nn as nn


class MLP(nn.Module):
    def __init__(self, dims, activation):
        super().__init__()

        assert len(dims) > 1
        assert activation == 'sigmoid' or activation == 'relu'

        layers = []
        for i in range(len(dims)-1):
            if i < len(dims) - 2:
                layers.append(nn.Linear(dims[i], dims[i+1]))
                layers.append(nn.Sigmoid()
                              if activation == 'sigmoid' else nn.ReLU())
            else:
                layers.append(nn.Linear(dims[i], dims[i+1], bias=False))

        self.mlp = nn.Sequential(*layers)

    def forward(self, x):
        x = self.mlp(x)
        return x


class AMLP(nn.Module):
    def __init__(self, dims, activation):
        super().__init__()

        assert len(dims) > 1
        assert dims[0] > 0
        dims_ = [1] + dims[1:]

        self.feature_mlp = nn.ModuleList([MLP(dims_, activation)
                                          for _ in range(dims[0])])

    def forward(self, x):
        x = torch.cat([
            self.feature_mlp[i](x[:, [i]]) for i in range(self.dims[0])],
            dim=-1).sum(axis=-1, keepdim=True)
        return x


class DefuseNet(nn.Module):

    def __init__(self, model_type, dims, activation):
        super().__init__()

        assert len(dims[0]) >= 2
        assert len(dims[1]) == 1
        assert dims[0][-1] == 1

        if model_type == 'mlp':
            self.functional = MLP(dims[0], activation)
        elif model_type == 'amlp':
            self.functional = AMLP(dims[0], activation)
        else:
            raise ValueError('Invalid model type.')

        if dims[1][0] > 0:
            self.linear = nn.Linear(dims[1][0], 1, bias=True)
        else:
            self.bias = torch.nn.Parameter(torch.zeros(1))
            self.linear = lambda _: self.bias

        self.feaure_weight = self.functional.mlp[0].weight

    def forward(self, x, z):
        x = self.functional(x) + self.linear(z)
        return x

    def smooth_tlp(self, param_norm):
        tlp = torch.log(0.01 + param_norm/100) * 10
        return tlp

    def reg(self, sparse_type):
        param_norm = torch.norm(self.feaure_weight, p="fro", dim=0)
        if sparse_type == 'tlp':
            return self.smooth_tlp(param_norm)
        elif sparse_type == 'l1':
            return param_norm
        else:
            raise ValueError('Invalid sparsity type.')


def main():

    # assess accuracy
    pass


if __name__ == '__main__':
    main()
