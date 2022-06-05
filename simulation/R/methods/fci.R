
causal_discovery_RFCI <- function(y) {
    suffStat <- list(C = cor(y), n = nrow(y))
    out <- rfci(
        suffStat = suffStat,
        p = ncol(y),
        skel.method = "stable",
        indepTest = gaussCItest,
        alpha = 0.001,
        verbose = FALSE
    )

    list(out = out, u = out@amat)
}



