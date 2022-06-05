import torch
import torch.nn as nn
import torch.optim as optim


class DefuseTrainer:
    def __init__(self, train_config, defuse_net, optimizer=None):

        self.n_epochs = train_config['n_epochs'] if train_config['n_epochs'] else [
            500, 5000]
        self.penalty_type = train_config['penalty_type'] if train_config['penalty_type'] else [
            'l1', 'tlp']
        self.penalty_param = train_config['penalty_param'] if train_config['penalty_param'] else [
            1e-4, 1e-2]

        assert len(self.penalty_type) == len(
            self.penalty_param) == len(self.n_epochs)

        self.defuse_net = defuse_net
        self.optimizer = optimizer if optimizer else optim.Adam(
            defuse_net.parameters(), lr=1e-1)
        self.loss = nn.MSELoss()

    def split_sample(self, x, z, y):
        """
        x is [n, d0] tensor
        z is [n, d1] tensor        
        y is [n] tensor
        """
        x = (x - x.mean(dim=0))/x.std(dim=0)
        z = (z - z.mean(dim=0))/z.std(dim=0)

        n = x.shape[0]
        n_val = int(0.1 * n)

        ind = torch.randperm(n)
        t_ind, v_ind = ind[:-n_val], ind[-n_val:]

        xt, zt, yt = x[t_ind, :], z[t_ind, :], y[t_ind]
        xv, zv, yv = x[v_ind, :], z[v_ind, :], y[v_ind]

        return xt, zt, yt, xv, zv, yv

    @torch.no_grad()
    def validate(self, xv, zv, yv):
        yp = self.defuse_net(xv, zv)
        loss = self.loss(yp, yv)
        return loss

    def train(self, x, z, y):
        xt, zt, yt, xv, zv, yv = self.split_sample(x, z, y)

        losses = []

        for k in range(len(self.n_epochs)):
            for epoch in range(self.n_epochs[k]):
                yf = self.defuse_net(xt, zt)
                loss_train = self.loss(
                    yf, yt) + self.penalty_param[k] * sum(self.defuse_net.reg(self.penalty_type[k]))
                self.optimizer.zero_grad()
                loss_train.backward()
                self.optimizer.step()

                if epoch % 250 == 0:
                    loss_valid = self.validate(xv, zv, yv)
                    losses.append(loss_valid)

                    if loss_valid == min(losses):
                        checkpoint = {
                            'epoch': epoch,
                            'model_state_dict': self.defuse_net.state_dict(),
                            'optimizer_state_dict': self.optimizer.state_dict(),
                            'loss': loss_valid,
                        }

        self.defuse_net.load_state_dict(checkpoint['model_state_dict'])
        return losses, checkpoint

    @torch.no_grad()
    def predict(self, x, z):
        x = (x - x.mean(dim=0))/x.std(dim=0)
        z = (z - z.mean(dim=0))/z.std(dim=0)
        return self.defuse_net(x, z)
