
#configurations

kRpath <- here::here("02scripts/R")
path_sql <- here::here("03processed-data/Richard.sqlite3")
path_sims <- here::here("03processed-data/apsimxFiles/")
path_EDAfigures <- here::here("05figures/klEDA/")
#plan 
source(file.path(kRpath, "functions.R"))
source(file.path(kRpath, "packages.R"))

source(file.path(kRpath, "EditApsimx.R"))
source(file.path(kRpath, "plan.R"))
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
drake::make(plan_config, lock_envir = F, memory_strategy = "autoclean", 
            garbage_collection = TRUE)

# # Analysis plan will  ---------------------------------------------------


# Process all simulation output 
# Identify the best fit parameters for SKL, KLR and RFV regarding to soil water
# profile
# Draw graphs of top 3 best fit 
# Output a table of real best fit 
drake::make(plan_analysis, lock_envir = F, memory_strategy = "autoclean", 
            garbage_collection = TRUE)

# # Soil water plan will  -------------------------------------------------


# Process all simulation output 
# Identify the best fit parameters for SKL, KLR and RFV regarding to soil water
# in each layer
# Draw graphs of top 3 best fit for each layer 
# Output a table of real best fit 
drake::make(plan_SW, lock_envir = F, memory_strategy = "autoclean", 
            garbage_collection = TRUE)



# Calibrate layer by layer ------------------------------------------------

# Constant
source(file.path(kRpath, "EditApsimxCalibrateLayers.R"))
source(file.path(kRpath, "plan_LayerCalibr.R"))
apsimx <- "C:/Data/ApsimX/ApsimXLatest/Bin/Models.exe"
drake::make(plan_LayerCalibr, lock_envir = F, memory_strategy = "autoclean", 
            garbage_collection = TRUE)


library(visNetwork) 
vis_drake_graph(
  plan_config, targets_only = TRUE,
  font_size = 25,
  # file = "05figures/dependency.png",
  navigationButtons = FALSE
  # parallelism = "clustermq",
  # jobs = 16
)
vis_drake_graph(
  plan_analysis, targets_only = TRUE,
 
  # file = "05figures/dependency.png",
  navigationButtons = FALSE
  # parallelism = "clustermq",
  # jobs = 16
)
vis_drake_graph(
  plan_SW, targets_only = TRUE,
  
  # file = "05figures/dependency.png",
  navigationButtons = FALSE
  # parallelism = "clustermq",
  # jobs = 16
)
drake_ggraph(plan)
