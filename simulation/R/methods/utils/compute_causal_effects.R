compute.causal.effects <- function(S.est.lrps, ges.fit, p, n, dataset) {
  Sig.est.lrps <- solve(S.est.lrps)
  fake.data <- rmvnorm(max(n, 2 * p), mean = rep(0, p), sigma = Sig.est.lrps)
  e <- eigen(Sig.est.lrps)
  sqrt.true.cov.mat <- e$vectors%*%sqrt(diag(e$values))
  samp.cov.mat <- cov(fake.data)
  e <- eigen(samp.cov.mat)
  sqrt.samp.cov.mat <- e$vectors%*%sqrt(diag(e$values))
  fake.data <- t(sqrt.true.cov.mat%*%solve(sqrt.samp.cov.mat,t(fake.data)))
  fake.data <- as.data.frame(fake.data)
  obs.data <- fake.data
  obs.data <- scale(obs.data)
  
  
  u.amat <- as(ges.fit$essgraph, "matrix") * 1
  p <- ncol(u.amat)
  ig.graph <- igraph::graph_from_adjacency_matrix(u.amat, mode="directed")
  all.distances <- igraph::distances(ig.graph)
  estimated.effects.ges.ida <- matrix(0,p,p)
  for (i in 1:p){
    for (j in 1:p){
      if(is.infinite(all.distances[i,j])) {
        estimated.effects.ges.ida[i,j] <- 0
        next()
      }
      if(i != j)
        estimated.effects.ges.ida[i,j] <- min(abs(ida(i, j, cov(obs.data),as(ges.fit$essgraph, "graphNEL"),"local")))
    }
  }
  diag(estimated.effects.ges.ida) <- NA
  true.causal.effects <- dataset$true.causal.effects
  true.causal.effects <- abs(true.causal.effects)
  
  idx <- !is.na(as.vector(estimated.effects.ges.ida))
  true.causal.effects <- as.vector(true.causal.effects)[idx]
  estimated.effects.ges.ida <- as.vector(estimated.effects.ges.ida)[idx]
  
  target <- length(which(true.causal.effects>0.0001))
  target.set <- order(true.causal.effects, decreasing = TRUE)[1:target]
  #
  get.pr <- function(est.effects,target.set){
    order.est <- order(est.effects,decreasing=T)
    true.positive <- sapply(1:length(est.effects),function(x) length(intersect(target.set,order.est[1:x])))
    precision <- true.positive/(1:length(est.effects))
    recall <- true.positive/length(target.set)
    return(cbind(recall,precision))
  }
  ges.ida.pr <- get.pr(estimated.effects.ges.ida,target.set)
  random.pr <- get.pr(sample.int(length(estimated.effects.ges.ida)),target.set)
  
  list(IDA_prec_red=ges.ida.pr, RANDOM_prec_rec=random.pr)
}
