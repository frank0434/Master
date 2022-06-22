## This script is an example application for optimizing parameters for
## soybean phenology - updates FEM May 27th 2014 and SVA May 29th, 2014


## Load libraries
## If using this as a template for many cultivars/locations etc consider some form of parallelization
## For example using the parallel package or the older multicore
library(lattice)
library(coda)

## source functions. These functions should be in the same directory for this to work.
source("phenologyAPSIM.R")
source("optimPhenoFunc.R")

## Import data
met <- read.csv("met_ark.csv", header=TRUE, sep=',')
Measured <- read.csv("Measured_ark.csv", header=TRUE, sep=',')

## soybean cultivars starting values. 
## mg = maturity group (see also Table 3 - paper). 
## Note mg of 0.01 refers to "00"
## When a mg of 2.5 is used the R code interpolates values from mg 2 and 3
## to get closer starting values.  
## we assume pcrit1=pcrit2=pcrit, the same for the psens
## for cc, dd, and ee explanation see comments in "phenologyAPSIM.R" script
mg <- c(0.01,0,1:6)
pcrits <- c(14.35, 14.1, 13.84, 13.59, 13.4, 13.09, 12.83, 12.58)
psens <- c(0.148, 0.171, 0.203, 0.249, 0.285, 0.294, 0.303, 0.311)
ccs <- c(5, 5.6, 6, 6.4, 8, 8.4, 13.2, 11.2)
dds <- c(11.2, 11.7, 11.9, 12.3, 12.7, 13.2, 13.5, 12.8)
ees <- c(22.8, 23.8, 24.2, 25, 25.7, 26.7, 27.5, 26)
csv <- data.frame(mg=mg, pcrit1=pcrits, psen=psens, cc=ccs, ss=(dds+ees))

## Determine the number of simulations and the burnin period
## For this example we have 10,000 simulations and a burnin of 5,000
## It is better to have even higher values than these
nsim <- 1e4
burnin <- 5e3

## Optimizing experiments
nop <- nrow(unique(Measured[, c("Exp","Cultivar")]))

## Creating table with locations and cultivars
tbl0 <- unique(Measured[, c("Exp","Cultivar")])
tbl <- unique(Measured[, c("Exp","Cultivar","Year")])
tableresults <- data.frame(loc = rep(NA,nrow(tbl0)), cultivar=NA, cc.median=NA, cc.low=NA, cc.high=NA, ss.median=NA, ss.low=NA, ss.high=NA, rss=NA, cor=NA, Num=NA, GDcc=NA, GDss=NA, accept=NA, pcrit1=NA, psen=NA)
tableresults$loc <- factor(tableresults$loc, levels=unique(tbl0$Exp))

tpar <- 0.01
## determine values for the initial and the final
init <- 1; fin <- 2
## Running these two only takes about 30+ minutes
## In this case we are only running one cultivar for the sake of an example
## to run more change the fin to upto 8 in this case
t1 <- Sys.time()
for(i in init:fin){
  obsdat <- subset(Measured, Cultivar == tbl0[i,2] & Exp == tbl0[i,1])
  metdat <- subset(met, year %in% obsdat$Year & Exp == tbl0[i,1])
  expn <- i

  tableresults[expn,c("loc","cultivar")] <- obsdat[1,c("Exp","Cultivar")]

  ## Pick coefficients
  if(obsdat[1,"Cultivar"] == 0.01){
    ccsv <- subset(csv, mg == 0.01)
    pcrit1 <- ccsv$pcrit1
    psen <- ccsv$psen
  }else{
    if(abs(obsdat$Cultivar[1] - round(obsdat$Cultivar[1])) < 0.001){
      ccsv <- subset(csv, mg == round(obsdat[1,"Cultivar"]))
      pcrit1 <- ccsv$pcrit1
      psen <- ccsv$psen
    }else{
      ccsv <- subset(csv, mg == round(obsdat[1,"Cultivar"]))
      ccsv0 <- subset(csv, mg == trunc(obsdat[1,"Cultivar"]))
      ccsv1 <- subset(csv, mg == ceiling(obsdat[1,"Cultivar"]))
      deci <- 1 - (obsdat$Cultivar[1] - trunc(obsdat$Cultivar[1]))
      pcrit1 <- deci * ccsv0$pcrit1 + (1-deci) * ccsv1$pcrit1
      psen <- deci * ccsv0$psen + (1-deci) * ccsv1$psen
    }
  }

  scl <- 1
  ch1 <- mcmc_soyp(obs=obsdat, met=metdat, nsim=nsim, treat=obsdat$Treatment, scale=scl, seed=1235,
                            mu=c(ccsv$cc,ccsv$ss), pcrit1=pcrit1, psen=psen,
                            tpar=tpar)
  ch2 <- mcmc_soyp(obs=obsdat, met=metdat, nsim=nsim, treat=obsdat$Treatment, scale=scl, seed=345678,
                            mu=c(ccsv$cc,ccsv$ss), pcrit1=pcrit1, psen=psen,
                            tpar=tpar)
  ch3 <- mcmc_soyp(obs=obsdat, met=metdat, nsim=nsim, treat=obsdat$Treatment, scale=scl, seed=54321,
                            mu=c(ccsv$cc,ccsv$ss), pcrit1=pcrit1, psen=psen,
                            tpar=tpar)

  accpt <- mean(c(ch1$accept, ch2$accept, ch3$accept))

  ch3.cc <- mcmc.list(mcmc(ch1$cc),
                      mcmc(ch2$cc),
                      mcmc(ch3$cc))

  ch3.ss <- mcmc.list(mcmc(ch1$ss),
                      mcmc(ch2$ss),
                      mcmc(ch3$ss))

  gel.diag.cc <- unclass(gelman.diag(ch3.cc))$psrf[1]
  gel.diag.ss <- unclass(gelman.diag(ch3.ss))$psrf[1]

  mcc <- median(c(ch1$cc[burnin:nsim],
                  ch2$cc[burnin:nsim],
                  ch3$cc[burnin:nsim]))
  tableresults[expn,3] <- mcc
  tableresults[expn,4:5] <- quantile(c(ch1$cc[burnin:nsim],ch2$cc[burnin:nsim],ch3$cc[burnin:nsim]), probs=c(0.05,0.95))
  mss <- median(c(ch1$ss[burnin:nsim],ch2$ss[burnin:nsim],ch3$ss[burnin:nsim]))
  tableresults[expn,6] <- mss
  tableresults[expn,7:8] <- quantile(c(ch1$ss[burnin:nsim],ch2$ss[burnin:nsim],ch3$ss[burnin:nsim]), probs=c(0.05,0.95))

  ## RSS
  rss <- objfunM(cfs=c(mcc, mss), obs=obsdat, met = metdat, treat=obsdat$Treatment, op.level=1)
  tableresults[expn,9] <- rss

  ## Correlation
  crr <- corfunM(cfs=c(mcc, mss), obs=obsdat, met = metdat, treat=obsdat$Treatment, op.level=1)
  tableresults[expn,10] <- crr

  ## Number of obs
  tableresults[expn,11] <- nrow(obsdat)

  ## Gelman diagnostics
  tableresults[expn,c(12,13)] <- c(gel.diag.cc, gel.diag.ss)
  tableresults[expn,14] <- accpt

  ## Also collect pcrit1 and psen
  tableresults[expn,15] <- pcrit1
  tableresults[expn,16] <- psen

  ## Saving results from a specific simulation
  save(ch3.cc, ch3.ss, ch1, ch2, ch3,
       file=paste("Chains-",tableresults[expn,"loc"],"-",
         tableresults[expn,"cultivar"],".RData",sep=""))
}

t2 <- Sys.time()

tt <- t2 - t1

## Optional line of code that writes results to file
##write.csv(tableresults, file=paste("optimPhenoResults.csv",sep=""),
##          row.names=FALSE)

## final step: use the equations 2 and 3 (see manuscript) to convert 
## the optimized parameters to APSIM XY format. 
