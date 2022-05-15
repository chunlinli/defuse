

graph_generator <- function(p = 100, graph_type) {
    if (graph_type == "random") {
        graph <- random_graph(p)
    } else if (graph_type == "hub") {
        graph <- hub_graph(p)
    } else {
        stop("Invalid graph type")
    }
    return(graph)
}

random_graph <- function(p) {
    sparsity <- 1 / p
    u <- matrix(rbinom(p * p, 1, sparsity), p, p)
    u[lower.tri(u, diag = TRUE)] <- 0

    u
}

hub_graph <- function(p) {
    num_of_hub <- 2
    idx <- rep(1:num_of_hub, length.out = p)
    u <- matrix(0, p, p)
    for (k in seq_len(num_of_hub)) {
        u[k, idx == k] <- 1
    }
    diag(u) <- 0

    u
}

data_generator <- function(u, n) {
    p <- ncol(u)

    # sparse confounded errors
    # for larger depth, error variance is smaller
    num_lvars <- 10
    err <- matrix(rnorm(n * p), nrow = n)
    lvars <- matrix(rnorm(n * num_lvars), nrow = n)

    for (k in seq_len(num_lvars)) {
        err[, k] <- err[, k] + 2 * lvars[, k]
        err[, k + 1] <- err[, k + 1] + 2 * lvars[, k]
    }

    y <- err
    for (j in seq_len(p)) {
        if (length(which(u[, j] != 0)) > 0) {
            pa <- which(u[, j] != 0)
            y[, j] <- y[, j] + nonlinear_map(y[, pa])
        }
    }

    list(u = u, y = y)
}

nonlinear_map <- function(x) {
    x <- as.matrix(x)
    y <- rep(0, nrow(x))
    for (j in ncol(x)) {
        coef_amplitude <- runif(1, min = 2, max = 3)
        coef_phase <- runif(1, min = pi / 2, max = pi)
        y <- y + coef_amplitude * cos(coef_phase * x[, j])
    }
    y
}