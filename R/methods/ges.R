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