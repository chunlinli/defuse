library(ggplot2)
source("R/data_generation.R")

# max depth is 2
set.seed(1110)

n <- 500
u <- graph_generator(graph_type = "random")
data <- data_generator(u, n)

u <- data$u
y <- data$y

colSums(u)
colSums(u%*%u)
colSums(u%*%u%*%u)


an_mat <- 1*((solve(diag(100) - u) - diag(100)) != 0)
colSums(an_mat)

plot(x = y[, 81], y = y[,98])

loess.gcv <- function(x, y){
  nobs <- length(y)
  xs <- sort(x, index.return = TRUE)
  x <- xs$x
  y <- y[xs$ix]
  tune.loess <- function(s){
    lo <- loess(y ~ x, span = s)
    mean((lo$fitted - y)^2) / (1 - lo$trace.hat/nobs)^2
  }
  os <- optimize(tune.loess, interval = c(.01, 1))$minimum
  lo <- loess(y ~ x, span = os)
  list(x = x, y = lo$fitted, df = lo$trace.hat, span = os)
}

 
locreg <- with(data.frame(y[,81]), loess.gcv(x = y[, 81], y = y[,98]))
lines(locreg, lwd = 2, lty = 2, col = "red")

x <- y[, 81]
xs <- sort(x, index.return = TRUE)
x <- xs$x
z <- y[xs$ix, 98]
res <- z - locreg$y
qqnorm(res)

mean(res)
sd(res)


# try sparse additive model 
library(SAM)

n = 100
d = 500
X = 0.5*matrix(runif(n*d),n,d) + matrix(rep(0.5*runif(n),d),n,d)
## generating response
y = -2*sin(X[,1]) + X[,2]^2-1/3 + X[,3]-1/2 + exp(-X[,4])+exp(-1)-1
## Training
out.trn = samQL(X, y)
out.trn
## plotting solution path
plot(out.trn)
## generating testing data
nt = 1000
Xt = 0.5*matrix(runif(nt*d),nt,d) + matrix(rep(0.5*runif(nt),d),nt,d)
yt = -2*sin(Xt[,1]) + Xt[,2]^2-1/3 + Xt[,3]-1/2 + exp(-Xt[,4])+exp(-1)-1
## predicting response
out.tst = predict(out.trn,Xt)



m <- samQL(X = y[,an_mat[,98]!=0], y = y[,98], regfunc = "MCP", p = 20)

yp <- predict(m, y[,an_mat[,98]!=0])$values[,30]
z <- (y[,98] - yp)

qqnorm(z)
mean(z)
sd(z)

hist(z, freq=FALSE, breaks = 50)
lines(x = seq(from=-4,to=4,by=0.01), y = dnorm(seq(from=-4,to=4,by=0.01), mean = 0, sd = 1))

hist(y[,98], freq=FALSE, breaks = 50)


plot(m)

m$sse

m$func_norm




n <- 500
eps1<-rnorm(n)
eps2<-rnorm(n)
eps3<-rnorm(n)
eps4<-rnorm(n)

x2 <- 0.5*eps2
x1 <- 0.9*sign(x2)*(abs(x2)^(0.5))+0.5*eps1
x3 <- 0.8*x2^2+0.5*eps3
x4 <- -0.9*sin(x3) - abs(x1) + 0.5*eps4

X <- cbind(x1,x2,x3,x4)

trueDAG <- cbind(c(0,1,0,0),c(0,0,0,0),c(0,1,0,0),c(1,0,1,0))
## x4 <- x3 <- x2 -> x1 -> x4
## adjacency matrix:
## 0 0 0 1
## 1 0 1 0
## 0 0 0 1
## 0 0 0 0

estDAG <- CAM(X, scoreName = "SEMGAM", numCores = 1, output = TRUE, variableSel = FALSE, 
              pruning = TRUE, pruneMethod = selGam, pruneMethodPars = list(cutOffPVal = 0.001))

cat("true DAG:\n")
show(trueDAG)

cat("estimated DAG:\n")
show(estDAG$Adj)





