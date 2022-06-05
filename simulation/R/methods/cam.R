
causal_discovery_CAM <- function(y) {
    out <- CAM(
        y,
        scoreName = "SEMGAM",
        numCores = 1,
        output = FALSE,
        variableSel = TRUE,
        pruning = TRUE,
        pruneMethod = selGam,
        pruneMethodPars = list(cutOffPVal = 0.001)
    )

    list(out = out, u = out$Adj)
}
