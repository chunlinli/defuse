
metrics <- function(true_graph, estimate_graph) {

    true_edges <- (true_graph != 0) * 1
    skeleton <- (t(true_graph) != 0) * 1 + (true_graph != 0) * 1
    directed_edges <- (estimate_graph == 1) * 1
    undirected_edges <- (estimate_graph != 0) * 1 - directed_edges
    
    # true positive
    true_positive <- directed_edges * true_edges
    true_positive_undirected <- undirected_edges * skeleton
    true_positive <- true_positive + true_positive_undirected

    # false positive
    false_positive <- directed_edges * (skeleton != 1)
    false_positive_undirected <- undirected_edges * (skeleton != 1)
    false_positive <- false_positive + false_positive_undirected
    
    # reverse
    extra_directed_edge <- directed_edges * (!true_edges)
    reverse <- extra_directed_edge * (t(true_graph) != 0)
    
    estimated_size <- sum(directed_edges) + sum(undirected_edges) # PE
    negative_size <- 0.5 * nrow(true_graph) * (nrow(true_graph) - 1) - sum(true_edges) # N

    FDR <- (sum(reverse) + sum(false_positive)) / max(1, estimated_size)
    FPR <- (sum(reverse) + sum(false_positive)) / max(1, negative_size)
    TPR <- sum(true_positive) / max(1, sum(true_edges))
    
    estimated <- estimate_graph + t(estimate_graph)
    estimated_lower <- (estimated[lower.tri(estimated)] != 0) * 1
    truth <- true_graph + t(true_graph)
    truth_lower <- (truth[lower.tri(truth)] != 0) * 1
    extra <- (estimated_lower * (! truth_lower)) * 1
    missing <- (truth_lower * (! estimated_lower)) * 1

    # this computation is in favarable for undirected edges
    SHD <- sum(extra) + sum(missing) + sum(reverse)

    list(FDR = FDR, FPR = FPR, TPR = TPR, SHD = SHD)
}

debug <- FALSE

if (debug) {
    # test
    true_dag <- cbind(c(0, 1, 0, 0), c(0, 0, 0, 0), c(0, 1, 0, 0), c(1, 0, 1, 0))
    est_dag <- cbind(c(0, 1, 0, 1), c(0, 0, 0, 0), c(0, 1, 0, 0), c(0, 0, 1, 0))

    metrics(true_dag, est_dag)
}
