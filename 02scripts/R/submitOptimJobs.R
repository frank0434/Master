#!/usr/bin/env Rscript

# Submit optimisation jobs to backend
# Blame to Frank Liu


apsimx <- "apsimx-2020.08.04.5350.sif"
#Set up directories
apsimx_flag <- "/Edit"
apsimx_file <- here::here("03processed-data/apsimxFiles/ModifiedSKL_0.06Iversen12SD2.apsimx")
apsimx_sims_dir <- here::here("03processed-data/apsimxFiles/")
apsimx_config <- here::here("03processed-data/ConfigurationFiles/")
apsimx_obs <- here::here("03processed-data/CoverData/")
for(i in list(apsimx_sims_dir, apsimx_config,apsimx_obs)){
  if (!file.exists(i)) {
    cat("Creating the dir", i, "\r\n")
    dir.create(i)
  }
}
source(here::here("02scripts/R/optimisation.R"))
t1 = Sys.time()
#DEoptim
maxIt = 2
np = 3
KL_layer = 22
slurpnodes = c(paste0("[Soil].Physical.SlurpSoil.KL", "[1:", KL_layer,"]"," = "),
               "[SlurpSowingRule].Script.RFV = ",
               "[SlurpSowingRule].Script.KLReductionFactor = "
)
lower = c(0.005, 10,  0.0005)
upper = c(0.11, 35, 0.01)
# The observaion value that will be used as the benchmark
obspara = "SWC"

opt.res =
  DEoptim::DEoptim(fn=cost.function, 
                   lower = lower,
                   upper = upper,
                   control=list(NP=np * 10, itermax=maxIt, parallelType=1,
                                storepopfrom = 1,
                                packages = c('RSQLite'),
                                parVar = c(
                                  'slurpnodes',
                                  'apsimx',
                                  'apsimx_flag',
                                  'apsimx_file',
                                  'obspara',
                                  'apsimx_sims_dir',
                                  
                                  'APSIMEditFun', 
                                  'APSIMRun' ))
  )


save(opt.res, file =  file.path(apsimx_sims_dir,
                                paste0(Sys.Date(), 'opt.res', ".RData")))

fit.par = data.frame(estimates = opt.res$optim$bestmem, cost = opt.res$optim$bestval)


#output the statistical test
par = fit.par$estimates

write.csv(par, here::here("03processed-data/opt.par.csv"), row.names = F)
t2 = Sys.time()
t2-t1