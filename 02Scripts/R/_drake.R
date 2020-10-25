
#configurations

path_sql <- here::here("Data/ProcessedData/Richard.sqlite3")
path_sims <- here::here("Data/ProcessedData/apsimxFiles/")
path_EDAfigures <- here::here("05figures/klEDA/")
path_apsimx <- "C:/Data/ApsimX/ApsimXLatest/Bin/Models.exe"
#plan 
source("R/functions.R")
source("R/packages.R")

source("R/EditApsimx.R")
source("R/plan.R")
source("R/plan_SW.R")
source("R/plan_config.R")
use_python("c:/python")
# Constant

id_vars <- c("Experiment", "SowingDate", "Clock.Today")
Sites <- c("AshleyDene", "Iversen12")

stats_key <- c("Experiment", "SowingDate", "SimulationID", "KLR", "RFV", "SKL")
stats_key_SW <- c("Experiment", "SowingDate", "SimulationID", "KLR", "RFV", "SKL", "Depth")

stats_key_extra <- c(stats_key, "NSE", "R2", "RMSE")
stats_key_SW_extra <- c(stats_key_SW, "NSE", "R2", "RMSE")

# # Configuration plan will  ----------------------------------------------


# Create configuration files for slurp 
# Create CoverData as slurp input 
# Create apsimx files 
# Run all apsimx files - take long time 
# Run apsimx ----------------------------------------


drake_config(plan_config, verbose = 2)
