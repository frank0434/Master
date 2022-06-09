## Functions used for optimization
## Updates FEM May 27th 2014
## Updates SVA May 29th 2014

## The objfun is an objective function used to compare results from
## the phenology function with observed data.
## The first argument cfs is the vector of coefficients. Should be of length 2 or 3.

## The argument obs is for the observed data (see example file and table S1)
## The argument met is for the met data (see example file and table S2)
## The argument stages is used to determine which stages are used for comparing
##   observed and simulated data. If 'FL' is selected only flowering will be compared.
##   If 'FL' and 'PM' are selected they will both be compared between observed and simulated.
## The argument op.level has three options. 0 and 1 will be used when optimizing one or two
##   parameters. 2 will be used when comparing 3 parameters.
## The parameter pcrit1 is the critical photoperiod and will only be used when selecting
##   op.level 0 or 1
## The argument psen is for the sensitivity to the photoperiod
## This function returns the residual sums of squares

objfun <- function(cfs, obs, met, stages = c("FL", "PM"), op.level=1, pcrit1=13, psen=0.249){  

  if(op.level == 1 || op.level == 0){
    res <- phenology(obs=obs, met=met, cc=cfs[1], ss=cfs[2], pcrit1=pcrit1, psen1=psen, psen2=psen)
  }else{
    res <- phenology(obs=obs, met=met, cc=cfs[1], ss=cfs[2], pcrit1=cfs[3], psen1=psen, psen2=psen)
  }
  v0 <- as.vector(res$days_SOW_PM[stages])
  v1 <- c(matrix(data=v0,length(stages),1))
  v2 <- as.integer(matrix(data=as.vector(obs[1,][stages]),length(stages),1))
  dff <-  v1-v2
  rss <- sum(dff^2)
}

## The function below uses the objfun for comparing multiple instances
## such as different locations or treatments. This assumes that the
## observed data has a column called 'Treatment'.

objfunM <- function(cfs, obs, met, treat=NULL, stages = c("FL", "PM"), op.level=1, pcrit1=13, psen=0.249){  # multiple, loops accros treatments
  
  n.o <- nrow(obs)
  rssV <- numeric(n.o)
  if(nrow(met) == 0) stop("met data has zero rows")
  
  years <- obs[,"Year"]

  for(i in 1:n.o){
    
    if(!missing(treat)){
      curr.met <- subset(met, year == years[i])
      rssV[i] <- objfun(cfs=cfs, obs=obs[obs$Treatment == treat[i],], met=curr.met, stages=stages, op.level=op.level,
                        pcrit1=pcrit1, psen=psen)      
    }else{
      curr.met <- met
      rssV[i] <- objfun(cfs=cfs, obs=obs, met=curr.met, stages=stages, op.level=op.level,
                        pcrit1=pcrit1, psen=psen)
    } 
  }

  rss <- sum(rssV, na.rm=TRUE)
  return(rss)  
}

## The function below 'corfun' is similar to the objfun but it
## computes the correlation between observed and simulated

corfun <- function(cfs, obs, met, stages = c("FL", "PM"), op.level=1, pcrit1=13, psen=0.249){  

  if(op.level == 0){
    res <- phenology(obs=obs, met=met, cc=cfs[1], ss=cfs[2], pcrit1=pcrit1, psen1=psen, psen2=psen)
  }
  if(op.level == 1){
    res <- phenology(obs=obs, met=met, cc=cfs[1], ss=cfs[2], pcrit1=pcrit1, psen1=psen, psen2=psen)
  }
  if(op.level == 2){
    res <- phenology(obs=obs, met=met, cc=cfs[1], ss=cfs[2], pcrit1=cfs[3], psen1=psen, psen2=psen)
  }
  v0 <- as.vector(res$days_SOW_PM[stages])
  v1 <- c(matrix(data=v0,length(stages),1))
  v2 <- as.integer(matrix(data=as.vector(obs[1,][stages]),length(stages),1))
  crr0 <- sum((v1 - v2)^2)
  crr1 <- sum((v2 - mean(v2))^2)
  crr <- 1 - crr0/crr1
  return(crr)
}

## The functoin below 'corfunM' computes the correlation using the
## corfun. It is similar to objfunM in that it cycles through multiple
## years and treatments

corfunM <- function(cfs, obs, met, treat=NULL, stages = c("FL", "PM"), op.level=1, pcrit1=13, psen=0.249){  # multiple, loops accros treatments
  
  n.o <- nrow(obs)
  corV <- numeric(n.o)
    
  years <- obs[,"Year"]

  for(i in 1:n.o){
    
    if(!missing(treat)){
      curr.met <- subset(met, year == years[i])
      corV[i] <- corfun(cfs=cfs, obs=obs[obs$Treatment == treat[i],], met=curr.met, stages=stages,
                        op.level=op.level, pcrit1=pcrit1, psen=psen)      
    }else{
      curr.met <- met
      corV[i] <- corfun(cfs=cfs, obs=obs, met=curr.met, stages=stages,
                        op.level=op.level, pcrit1=pcrit1, psen=psen)
    } 
  }

  cor <- mean(corV, na.rm=TRUE)
  return(cor)  
}

## The function below is the main optimization tool
## The arguments obs and met are the observed data and met data (see examples)
## The number of simulations is controlled with the nsim parameter
## The op.level controls the optimization level. op.level=0 will only
##   attempt to optimize the parameter that controls time to flowering
##   The op.level = 1 will optimize two parameters that control flowering and maturity
##   The op.level = 2 will optimize three parameters that control flowering, maturity and critical photoperiod
## The argument mu is a vector (length = 3) with the starting values for the three parameters being optimized
## The argument sigma is a vector (length = 3) that control the standard deviation of the three parameters
##   modifying this vector is not necessarily recommended. It can be more beneficial to modify the scale or
##   tpar
## The argument stages is used to determine which stages are used for comparing
##   observed and simulated data. If 'FL' is selected only flowering will be compared.
##   If 'FL' and 'PM' are selected they will both be compared between observed and simulated.
## The scale srgument is used to increase or decrease the standard deviations of the three parameters.
##   It can be tuned to deal with the issue of chains that are too 'sticky' or not exploring the parameter space enough
## The argument seed is used to control the random simulations so that results can be reproduced. It is used inside the set.seed function
## The argument treat is passed to the objfunM function to specify the 'treatment'.
## The pcrit1 is the critical photoperiod
## The psen argument is the photoperiod sensitivity
## The ss0 argument is a default value for parameter ss (used only with op.level=0)
## The argument tpar is the tuning parameter. It affects the scale parameter.
##   the idea is that it guarantees a certain rejection rate
## the mcmc_soyp function returns a list with the following components
##
##  - rss: the vector with the progress of the residual sums of squares
##  - cc: the vector with the progress of the cc parameter
##  - pcrit: the vector with the progress of the pcrit parameter
##  - accept: the acceptance rate (number of moves accepted over total moves)
##  - scale: the progress of the scale parameter, since the tpar parameter could be modifying it.

mcmc_soyp <- function(obs, met, nsim=3000, op.level=1, mu=c(11,32,13), sigma=c(4,9,0.25),
                      stages = c("FL","PM"),
                      scale=1, seed=1234, treat, pcrit1=13, psen=0.249, ss0=30, tpar=0.1){ 

  ## tpar is a tunning parameter
  set.seed(seed)
  old.rss <- 1e7
  pcrit10 <- pcrit1

  j <- 1

  sigma <- sigma * scale
  sigma0 <- sigma
  scaleVec <- numeric(nsim)
  
  rssvec <- numeric(nsim)
  ccvec <- numeric(nsim)
  ssvec <- numeric(nsim)
  pcritvec <- numeric(nsim)

  pcc <- mu[1]
  pss <- mu[2]
  ppcrit <- mu[3]
  cc.old <- pcc
  ss.old <- pss
  pcrit.old <- ppcrit
  
  for(i in 1:nsim){

    ## First step is to sample from a multivariate normal
    cc <- rnorm(1, mean=mu[1], sd = sigma[1])
    ss <- rnorm(1, mean=mu[2], sd = sigma[2])
    if(op.level == 2) pcrit1 <- rnorm(1, mean=mu[3], sd = sigma[3])
  
    ## Second step is to compute the rss
    if(op.level == 0){
      rss <- objfunM(cfs = c(cc,ss0), obs=obs, met=met, treat=treat, pcrit1=pcrit10, psen=psen, stages=stages)
    }
    if(op.level == 1){
      rss <- objfunM(cfs = c(cc,ss), obs=obs, met=met, treat=treat, pcrit1=pcrit10, psen=psen, stages=stages)
    }
    if(op.level == 2){
      rss <- objfunM(cfs = c(cc,ss, pcrit1), obs=obs, met=met, treat=treat, psen=psen, op.level=2, stages=stages)
    }

    rnum <- dnorm(cc, mean = pcc, sd = sigma[1])*dnorm(ss, mean = pss, sd = sigma[2])
    rden <- dnorm(cc.old, mean = pcc, sd = sigma[1])*dnorm(ss.old, mean = pss, sd = sigma[2])

    lratio <- log(rnum) - log(rden)
                
    ## Compute the ratio
    lmr <- -rss + old.rss #+ lratio

    U <- runif(1)

    if(lmr > log(U)){
      if(op.level == 0){
        mu <- cc
      }
      if(op.level == 1){
        mu <- c(cc,ss)
      }
      if(op.level == 2){
        mu <- c(cc,ss,pcrit1)
      }
      old.rss <- rss
      j <- j + 1
      scale <- scale * (1+tpar)
      sigma <- sigma * scale 
    }else{
      scale <- scale * (1-tpar)
      sigma <- sigma * scale
    }

    ## Collect results
    rssvec[i] <- rss
    if(op.level == 0){
      ccvec[i] <- mu
      scaleVec[i] <- scale
    }
    if(op.level == 1){
      ccvec[i] <- mu[1]
      ssvec[i] <- mu[2]
      scaleVec[i] <- scale
    }
    if(op.level == 2){
      ccvec[i] <- mu[1]
      ssvec[i] <- mu[2]
      pcritvec[i] <- mu[3]
      scaleVec[i] <- scale
    }
  }
  if(op.level == 0){
    ans <- list(rss=rssvec, cc=ccvec, accept=j/nsim, scale=scaleVec)
  }
  if(op.level == 1){
    ans <- list(rss=rssvec, cc=ccvec, ss=ssvec, accept=j/nsim, scale=scaleVec)
  }
  if(op.level == 2){
    ans <- list(rss=rssvec, cc=ccvec, ss=ssvec, pcrit=pcritvec,
                accept=j/nsim, scale=scaleVec)
  }

  return(ans)
}
