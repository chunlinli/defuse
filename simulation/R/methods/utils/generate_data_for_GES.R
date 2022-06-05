generate.data.for.GES <- function(Sest, n, p) {
  S.est.lrps <- Sest
  Sig.est.lrps <- solve(S.est.lrps)
  fake.data <- rmvnorm(max(n,2*p), mean = rep(0, p), sigma = Sig.est.lrps)
  e <- eigen(Sig.est.lrps)
  sqrt.true.cov.mat <- e$vectors%*%sqrt(diag(e$values))
  samp.cov.mat <- cov(fake.data)
  e <- eigen(samp.cov.mat)
  sqrt.samp.cov.mat <- e$vectors%*%sqrt(diag(e$values))
  fake.data <- t(sqrt.true.cov.mat%*%solve(sqrt.samp.cov.mat,t(fake.data)))
  fake.data <- as.data.frame(fake.data)
  obs.data <- fake.data
}
