library(lrpsadmm)
library(mvtnorm)
library(bnlearn)

causal_discovery_LRpS_GES <- function(y) {
    y <- scale(y)
    n <- nrow(y)
    p <- ncol(y)
    gammas <- c(0.05, 0.07, 0.1, 0.12, 0.15, 0.17, 0.2)
    xval_path <- lrpsadmm.cv(
        X = y,
        gammas = gammas,
        covariance.estimator = cor,
        n.folds = 5,
        verbose = FALSE,
        n.lambdas = 40,
        lambda.ratio = 1e-04,
        backend = "RcppEigen"
    )
    selected_s <- xval_path$best.fit$fit$S
    fake_data <- generate.data.for.GES(
        Sest = selected_s,
        n = n,
        p = p
    )
    lrps_ges_output <- run.GES.and.select.with.BIC(
        obs.data = fake_data,
        nv = p,
        sim.data = data.frame(y)
    )

    list(out = lrps_ges_output, u = lrps_ges_output$best.essgraph)
}





# n <- 500
# eps1 <- rnorm(n)
# eps2 <- rnorm(n)
# eps3 <- rnorm(n)
# eps4 <- rnorm(n)

# x2 <- 0.5 * eps2
# x1 <- 0.9 * sign(x2) * (abs(x2)^(0.5)) + 0.5 * eps1
# x3 <- 0.8 * x2^2 + 0.5 * eps3
# x4 <- -0.9 * sin(x3) - abs(x1) + 0.5 * eps4

# X <- cbind(x1, x2, x3, x4)

# trueDAG <- cbind(c(0, 1, 0, 0), c(0, 0, 0, 0), c(0, 1, 0, 0), c(1, 0, 1, 0))
# ## x4 <- x3 <- x2 -> x1 -> x4
# ## adjacency matrix:
# ## 0 0 0 1
# ## 1 0 1 0
# ## 0 0 0 1
# ## 0 0 0 0

# X <- scale(X)
# gammas <- c(0.05, 0.07, 0.1, 0.12, 0.15, 0.17, 0.2)
# xval.path <- lrpsadmm.cv(
#     X = X, gammas = gammas, covariance.estimator = cor, n.folds = 5,
#     verbose = FALSE, n.lambdas = 40, lambda.ratio = 1e-04, backend = "R"
# )
# selected.S <- xval.path$best.fit$fit$S

# selected.S




# source("./R/methods/utils/simulate_data_from_latent_dag.R")
# p <- 50 # Number of obvserved variables
# h <- 3 # Number of hidden variables
# n <- 500 # Number of samples
# set.seed(0)
# toy.data <- simulate.latent.DAG.data(nl = h, nv = p, ss = n, sp = 0.05)
# X <- toy.data$data # The observed data
# X <- scale(X)

# gammas <- c(0.05, 0.07, 0.1, 0.12, 0.15, 0.17, 0.2)
# xval.path <- lrpsadmm.cv(
#     X = X, gammas = gammas, covariance.estimator = cor, n.folds = 5,
#     verbose = TRUE, n.lambdas = 40, lambda.ratio = 1e-04, backend = "R"
# )

# source("./R/methods/utils/generate_data_for_GES.R")
# selected.S <- xval.path$best.fit$fit$S
# # Because the GES function of pcalg can only take a data matrix as input and not a covariance matrix,
# # we simulate data with the exact same sample covariance matrix as the estimated one.
# # This is a trick that lets use the GES function of pcalg.
# fake.data <- generate.data.for.GES(Sest = selected.S, n = n, p = ncol(selected.S))

# source("./R/methods/utils/run_GES.R")
# source("./R/methods/utils/compute_metrics.R")
# source("./R/methods/utils/process_curve.R")

# # We now compute the GES path on the resulting data and compute the BIC at each step.
# X <- data.frame(X)
# lrps.ges.output <- run.GES.and.select.with.BIC(obs.data = fake.data, nv = ncol(X), sim.data = X)