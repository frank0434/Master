#!/usr/bin/env Rscript

# Submit optimisation jobs to backend
# Blame to Jian Liu, Junqi Zhu
library(RLinuxModules)
apsimxsif = "apsimx/2020.08.04.5350"
module(paste("load", apsimxsif))
module("load openlava")
module("load asub/2.1")
module ("load R/3.6.1")

apsimx <- "apsimx-2020.08.04.5350.sif"
#Set up directories
apsimx_flag <- "/Edit"
apsimx_file <- here::here("grapevine_base.apsimx")
apsimx_sims_dir <- here::here("apsimxFiles/")

source(here::here("optimisation_14_8.R"))

t1 = Sys.time()
#DEoptim
maxIt = 70
np = 6
idLength = 4


##branching rate 0.6, 0.9
#RUE 1,2, c(0.8, 1.3)
#priority factor
#shoot biomass, 0.3
#root,trunk, cordon structural biomass, 0.3
#root,trunk, cordon storage, 0.2-0.8
#berry biomass, 1.2 

#priority factor of shoot
#priority factor of root and trunk

editNodes = 
  c( 
    ".Simulations.Replacements.Grapevine.Structure.BranchingRate.ScaleFactor.FixedValue = ", 
    ".Simulations.Replacements.Grapevine.Leaf.Photosynthesis.RUE.Vegetative.Constant.FixedValue =",
    ".Simulations.Replacements.Grapevine.Leaf.Photosynthesis.RUE.Reproductive.Constant.FixedValue =",
    ".Simulations.Replacements.Grapevine.Shoot.DMDemandPriorityFactors.Structural.FixedValue =",
    ".Simulations.Replacements.Grapevine.Berry.DMDemandPriorityFactors.Structural.FixedValue =",
    '.Simulations.Replacements.Grapevine.Fibrousroot.DMDemandPriorityFactors.Structural.FixedValue =',
    '.Simulations.Replacements.Grapevine.Fibrousroot.DMDemandPriorityFactors.Storage.Juvenile.Constant.FixedValue = ',
    '.Simulations.Replacements.Grapevine.Fibrousroot.DMDemandPriorityFactors.Storage.Reproductive.Constant.FixedValue ='
    
  )


lower = c(0.6, 0.7, 0.9,  0.1,  1.1,  0.1,  0.1, 0.1)
upper = c(0.95, 1.1, 1.4, 0.4,  2,    0.5,  1,   1.2)

# initialPop = matrix(nrow = 40, ncol=4)
# initialPop[1,] = c(5.323079,30.514018,42.386243,24.456818)
# initialPop[2,] = c(3.150276,28.458947,38.594053,24.581769)
# initialPop[3,] = c(5.594849,30.213733,40.648709,20.775019)
# initialPop[4,] = c(4.447903,28.599034,37.316855,21.768780)
# initialPop[5,] = c(2.51085677,22.2450914,40.31615624, 44.00759)
# 
# for(i in 6:40) 
# {
#   if (i %% 5 == 1) initialPop[i,] = initialPop[1,] + 
#         runif(1)* (initialPop[3,] - initialPop[1,])
#   
#   if (i %% 5 == 2) initialPop[i,] = initialPop[2,] + 
#         runif(1)* (initialPop[3,] - initialPop[2,])
#   
#   if (i %% 5 == 3) initialPop[i,] = initialPop[3,] + 
#         runif(1)* (initialPop[4,] - initialPop[3,])
#   
#   if (i %% 5 == 4) initialPop[i,] = initialPop[4,] + 
#         runif(1)* (initialPop[3,] - initialPop[4,])
#   
#   if (i %% 5 == 0) initialPop[i,] = initialPop[5,] + 
#         runif(1)* (initialPop[3,] - initialPop[5,])
#   
#   
# }

# The observaion value that will be used as the benchmark
# obspara = c("FloweringDAWS", "VeraisonDAWS")
obspara = c("leaf.area.vine", "leaf.dw.vine","shoot.dw.mean", "TotalBerryDW", 
            'total.NSC.concentration.trunk', 'total.NSC.concentration.root' )

opt.res =
  DEoptim::DEoptim(fn=cost.function, 
                   lower = lower,
                   upper = upper,
                   control=list(NP=np*10,
                                itermax=maxIt, 
                                strategy = 1,
                                parallelType=1,
                                storepopfrom = 1,
                                #initialpop = initialPop,
                                packages = c('RSQLite'),
                                parVar = c(
                                  'editNodes',
                                  'apsimx',
                                  'apsimx_flag',
                                  'apsimx_file',
                                  'apsimx_sims_dir',
                                  'APSIMEditFun', 
                                  'APSIMRun',
                                  'llik',
                                  'calcCost',
                                  'idLength')),
                   
                   obspara = obspara
                   
  )

save(opt.res, file =  file.path(here::here(paste0('IntRes/', Sys.Date(), 'opt.res', ".RData"))))

fit.par = data.frame(estimates = opt.res$optim$bestmem, cost = opt.res$optim$bestval)

#output the statistical test
par = fit.par$estimates
write.csv(par, file.path(
  here::here(paste0('IntRes/', Sys.Date(), "opt.par.csv"))), row.names=F)
          
t2 = Sys.time()
t2-t1