
# unify the interface of the methods
causal_discovery <- function(y, method) {

    if (method == "CAM") {
        causal_discovery_CAM(y)
    } else if (method == "LRpS-GES") {
        causal_discovery_LRpS_GES(y)
    } else if (method == "RFCI") {
        causal_discovery_RFCI(y)
    } else {
        stop("Unknown method")
    }

}

debug <- TRUE
method <- "RFCI"
if (debug) {

    n <- 500
    p <- 50
    u <- graph_generator(p, "random")
    y <- data_generator(u, n)$y

    out <- causal_discovery(y, method=method)
    metrics(out$u,u)
}


