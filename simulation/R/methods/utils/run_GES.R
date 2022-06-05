run.GES.and.select.with.BIC <- function(obs.data, nv, sim.data) {
  
  rho <- 100000 # Compute the path, starting with this value of Rho
  rho.base <- 1.1 # The next value of Rho is Rho / 1.1
  path <- list()
  counter <- 1
  while(T) {
    score <- new("GaussL0penObsScore", obs.data, lambda = rho)
    start.time <- Sys.time()
    ges.fit <- ges(score)
    end.time <- Sys.time()
    time.taken <- end.time - start.time
    
    u.amat <- as(ges.fit$essgraph, "matrix") * 1
    if(sum(u.amat) == 0) {
      rho <- rho / rho.base
      next()
    }
    
    # Compute the BIC
    bn <- empty.graph(colnames(obs.data))
    amat(bn) <- as(ges.fit$repr, "matrix") 
    bn <- bn.fit(bn, as.data.frame(obs.data))
    BIC <- BIC(bn, data = as.data.frame(obs.data))
    LogLik <- logLik(bn, data = as.data.frame(obs.data))
    NEdges <- sum(amat(bn)!=0)
    
    est.cpdag <- as(ges.fit$essgraph, "matrix") * 1
    # Compare to the true CPDAG
    #perf.metrics <- compute_metrics(true.dag = sim.data$true.obs.dag.amat, 
    #                                est.cpdag = est.cpdag)
    
    # Record these results
    path[[counter]] <- list()
    path[[counter]]$rho <- rho
    #path[[counter]]$metric <- perf.metrics
    path[[counter]]$NEdges <- NEdges
    path[[counter]]$BIC <- BIC
    path[[counter]]$LogLik <- LogLik
    path[[counter]]$fitting.time <- time.taken
    
    if (NEdges / choose(nv, 2) > 0.5) {
      break()
    }
    
    counter <- counter + 1
    rho <- rho / rho.base
  }
  
  # Get the value of lambda that gives the best BIC
  BIC <- unlist(sapply(path, function(a){get("BIC", a)}))
  idx <- which.max(BIC)
  rho.bic <- unlist(sapply(path, function(a) {get("rho", a)}))[idx]
  
  # Refit the model with this value of Rho
  score <- new("GaussL0penObsScore", obs.data, lambda = rho.bic)
  ges.fit <- ges(score)
  u.amat <- as(ges.fit$essgraph, "matrix") * 1
  
  list(path=path, best.essgraph=u.amat, best.fit=ges.fit)
}