library(pcalg)
library(mvtnorm)

simulate.latent.DAG.data <- function(nl, nv, ss, sp, sp_l=0.8, outlier_fraction=0, transformation=function(x) x, network_type='er', hubness=1.0) {
  # nl : number latent variables
  # nv : number of observed variables
  # ss : sample size
  # sp : DAG sparsity
  # sp_l : Density of the connection between the number of latents and observed vars.
  q <- nl
  p <- nv
  nvar <- p+q
  n <- ss
  
  #generate random DAG
  if (network_type == 'er') {
      g <- pcalg::randomDAG(nvar, sp, lB=0, uB=1)
  } else {
      g <- randDAG(nvar, 2, method=network_type, wFUN=list(runif, min=0.0, max=1), par1=hubness)
  }
  amat <- as(g,"matrix")
  
  if(q > 0) {
    #The first q variables are going to be the latent variables and they are parents of 80% observed variables on average
    amat[1:q,-(1:q)] <- do.call('rbind',lapply(1:q,function(x) rbinom(p, 1, sp_l)*(runif(p))))
  }
  #change sign of 50% edge weights
  amat <- amat*matrix(sample(c(1,-1),nvar*nvar,replace=TRUE,prob=c(1/2,1/2)),nrow=nvar)
  #permute labels of the observed variables
  randperm <- q + sample.int(p)
  amat[(q+1):nvar,(q+1):nvar] <- amat[randperm,randperm]
  
  colnames(amat) <- rownames(amat) <- as.character(1:nvar)
  
  true.causal.effects <- solve(diag(nvar)-amat)
  if(q > 0) {
    true.causal.effects <- true.causal.effects[-(1:q),-(1:q)]
  }
  
  error.cov.mat <- diag(runif(nvar))
  true.cov.mat<- solve(diag(nvar)-t(amat))%*%error.cov.mat%*%solve(diag(nvar)-amat)
  true.prec.mat<- solve(true.cov.mat)
  true.prec.mat[abs(true.prec.mat) < 1e-08] <- 0
 
  #generate data
  if (outlier_fraction==0) {
    dat <- rmvnorm(n,mean=rep(0,nvar),sigma=true.cov.mat)
  } else {
    f = 1 - outlier_fraction
    dat1 <- rmvnorm(ceiling(f * n), mean=rep(0,nvar),sigma=true.cov.mat)
    dat2 <- rmvt(n - ceiling(f * n), sigma=true.cov.mat, df=1)
    dat <- rbind(dat1, dat2)
  }
  if(q > 0) {
    #remove the columns that corresponds to the latent variables
    obs.dat <- dat[,-(1:q)]
    true.obs.covmat <- true.cov.mat[-(1:q),-(1:q)]
    true.obs.dag.amat <- amat[-(1:q),-(1:q)]
  } else {
    obs.dat <- dat
    true.obs.covmat <- true.cov.mat
    true.obs.dag.amat <- amat
  }
  colnames(obs.dat) <- as.character(1:p)
  
  # Standardise the data
  obs.dat <- transformation(obs.dat)
  #for(i in 1:ncol(obs.dat)) {
  #  v <- obs.dat[,i]
  #  obs.dat[,i] <- (v - mean(v)) / sd(v)
  #}
  
  data <- list()
  data$network_type <- network_type
  data$hubness <- hubness
  data$outlier_fraction <- outlier_fraction
  data$tranformation <- transformation(10)
  data$data <- obs.dat
  data$full.dag.amat <- amat
  data$true.obs.dag.amat <- true.obs.dag.amat
  # Observed amat
  if(q > 0) {
    obs.dag.amat <- amat[-(1:q), -(1:q)]
  } else {
    obs.dag.amat <- amat
  }
  
  # Convert to a CPDAG
  true.cpdag <- dag2cpdag(as(obs.dag.amat!=0,"graphNEL"))
  data$true.cpdag <- true.cpdag
  true.cpdag.amat <- as(true.cpdag, "matrix")
  data$true.obs.cpdag.amat <- true.cpdag.amat
  
  data$true.causal.effects <- true.causal.effects
  data$true.prec.mat <- true.prec.mat  
  data
}
