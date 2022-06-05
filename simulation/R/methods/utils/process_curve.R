# This code takes a bunch of precision and recall values
# and 1) Corrects the curve so that it is non-increasing
# 2) Interpolates the precision at fixed recall values


process_curve <- function(d) {
  if(dim(d)[1] == 1) {
    print("Error 1")
    ww
    inter <- list(x=0.1*c(1:10), y=rep(NA,10))
    return(inter)
  }
  if(is.nan(d[1,2])) {
    print("Error 2")
    #ww
    inter <- list(x=0.1*c(1:10), y=rep(NA,10))
    return(inter)
  }
  if((sum(d[,2]) == 0) & (sum(is.nan(d[,1])) == nrow(d)) ) {
    print("Error 3")
    ww
    inter <- list(x=0.1*c(1:10), y=rep(NA,10))
    return(inter)
  }
  d[is.nan(d[,1]),1] <- 0
  
  d <- d[d[,2] >= 0,]
  # Record the unique values we have for each recall
  recalls <- unique(d[,2])
  
  if(length(recalls) == 1) {
    print("Error 4")
    inter <- list(x=0.1*c(1:10), y = rep(NA,10))
    return(inter)
  }
  # For each recall keep the highest precision
  pr <- matrix(NA, ncol=2, nrow=0)
  for(r in recalls) {
    idx <- d[,2] == r
    d2 <- d[idx,]
    if(sum(idx) == 1) {
      pr <- rbind(pr, c(r, d2[1]))
    } else {
      pr <- rbind(pr, c(r, max(d2[,1])))
    }
  }
  
  if(nrow(pr) == 1 & sum(pr) == 0) {
    print("Error 5")
    ww
    inter <- list(x=0.1*c(1:10), y=rep(0,10))
    return(inter)
  }
  # Make the curve non-increasing
  pr <- pr[order(pr[,1]),]
  for(i in 1:(nrow(pr)-1)) {
    r <- pr[i,1]
    p <- pr[i,2]
    m <- max(pr[(i+1):nrow(pr), 2])
    if (m <= p) {
      next()
    }
    idx <- which(pr[(i+1):nrow(pr), 2] == m)
    if(length(idx) == 1) {
      pr[i,2] <- pr[i+idx,2]
    } else{
      pr[i,2] <- pr[i+idx[1],2]
    }
  }
  # Interpolate
  #inter <- approx(x=pr[,1], y=pr[,2], xout=0.01*c(1:100), yright = 0, rule=2)
  inter <- approx(x=pr[,1], y=pr[,2], xout=0.01*c(1:100), rule=1)
  
  inter
}
