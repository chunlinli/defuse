compute_metrics <- function(true.dag, est.cpdag) {
  true.dag <- 1 * (true.dag !=0)
  true.cpdag <- as(dag2cpdag(as(true.dag, "graphNEL")), "matrix")
  
  get.skeleton <- function(A) {
    A <- 1 * ((A + t(A)) !=0)
    A
  }
  get.directed.edges <- function(A) {
    B <- ((A + t(A)) == 2) #Look at the undirected edges
    A[B] <- 0 # Remove them
    A
  }
  
  true.sk <- get.skeleton(true.cpdag)
  est.sk <- get.skeleton(est.cpdag)
  true.dir <- get.directed.edges(true.cpdag) # This gives only the directed edges of the CPDAG
  est.dir <- get.directed.edges(dag2cpdag(est.cpdag))
  # Just the skeleton
  prec.sk <- sum(true.sk * est.sk) / sum(est.sk)
  rec.sk <- sum(true.sk * est.sk) / sum(true.sk)
  # Do the same with the False Positive and FN rates
  tpr.sk <- rec.sk
  fpr.sk <- 1 - (sum((true.sk ==0) * (est.sk ==0)) / sum(true.sk == 0))
  
  # Now, look only at the directed edges of the CPDAG
  prec.dir <- sum(true.dir * est.dir) / sum(est.dir)
  rec.dir <- sum(true.dir * est.dir) / sum(true.dir)
  tpr.dir <- rec.dir
  fpr.dir <- 1 - (sum((true.dir ==0) * (est.dir ==0)) / sum(true.dir == 0))
  
  # Finally, compare the true DAG
  prec.dag <- sum(true.dag * est.cpdag) / sum(est.cpdag)
  rec.dag <- sum(true.dag * est.cpdag) / sum(true.dag)
  tpr.dag <- rec.dag
  fpr.dag <- 1 - (sum((true.dag ==0) * (est.cpdag ==0)) / sum(true.dag == 0))
  
  r <- list()
  r$prec.sk <- prec.sk
  r$rec.sk <- rec.sk
  r$prec.dir <- prec.dir
  r$rec.dir <- rec.dir
  r$prec.dag <- prec.dag
  r$rec.dag <- rec.dag
  
  r$tpr.sk <- tpr.sk
  r$fpr.sk <- fpr.sk
  r$tpr.dir <- tpr.dir
  r$fpr.dir <- fpr.dir
  r$tpr.dag <- tpr.dag
  r$fpr.dag <- fpr.dag
  
  r
}
