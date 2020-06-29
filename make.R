
#configurations

kRpath <- here::here("02scripts/R")
path_sql <- here::here("03processed-data/Richard.sqlite3")
path_sims <- here::here("03processed-data/apsimxFiles/")
path_EDAfigures <- here::here("05figures/klEDA/")
#plan 
source(file.path(kRpath, "functions.R"))
source(file.path(kRpath, "packages.R"))

source(file.path(kRpath, "EditApsimx.R"))
source(file.path(kRpath, "plan_analysis.R"))
source(file.path(kRpath, "plan_SW.R"))
source(file.path(kRpath, "plan_config.R"))

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


vis_drake_graph(
  plan_config, targets_only = TRUE,
  font_size = 25,
  navigationButtons = FALSE

)

drake::make(plan_config, lock_envir = F, memory_strategy = "autoclean", 
            garbage_collection = TRUE)
# # Analysis plan will  ---------------------------------------------------

