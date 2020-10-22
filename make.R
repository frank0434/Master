
#configurations
path_richard = "c:/Users/cflfcl/Dropbox/Data/APSIM_Sim.xlsx"
kRpath <- here::here("Scripts/R")

path_sims <- here::here("Data/ProcessedData/apsimxFiles/")
path_EDAfigures <- here::here("05figures/klEDA/")
path_cover <-  "Data/ProcessedData/CoverData/"
path_apsimx <- "C:/Data/ApsimX/ApsimXLatest/Bin/Models.exe"
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
biomass_cols <- c('Experiment', 'Clock.Today', 'SowingDate', 'Rep',
                  'Plot', 'Rotation.No.', 'Harvest.No.', 'Height','LAImod')
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


make(plan_config,  memory_strategy = "autoclean", 
     garbage_collection = TRUE)

vis_drake_graph(
  plan_config, targets_only = TRUE,
  font_size = 25,
  # file = "05figures/dependency.png",
  navigationButtons = TRUE,
  build_times = "none"
  # parallelism = "clustermq",
  # jobs = 16
)


# # Analysis plan will  ---------------------------------------------------


# Process all simulation output 
# Identify the best fit parameters for SKL, KLR and RFV regarding to soil water
# profile 
# Draw graphs of top 3 best fit 
# Output a table of real best fit 
vis_drake_graph(
  plan_analysis
  
  # file = "05figures/dependency.png",

  # parallelism = "clustermq",
  # jobs = 16
)
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

vis_drake_graph(
  plan_SW, targets_only = TRUE,
  
  # file = "05figures/dependency.png",
  navigationButtons = FALSE
  # parallelism = "clustermq",
  # jobs = 16
)

# Calibrate layer by layer ------------------------------------------------

# STEPS

## Execute this plan first
## 

# Constant
source(file.path(kRpath, "EditApsimxCalibrateLayers.R"))
source(file.path(kRpath, "plan_LayerCalibr.R"))
apsimx <- "C:/Data/ApsimX/ApsimXLatest/Bin/Models.exe"
KL_layers <- as.integer(seq(2, 22, by = 1))
KL_range <- seq(0.005, 0.11, by = 0.005)
path_sims2 <- here::here("03processed-data/apsimxFilesLayers")
path_layerkl <- here::here("05figures/kl_LayerByLayerCalibrationEDA/")
drake::make(plan_LayerCalibr, lock_envir = F, memory_strategy = "autoclean", 
            garbage_collection = TRUE)



vis_drake_graph(
  plan_LayerCalibr, targets_only = TRUE,
  
  # file = "05figures/dependency.png",
  navigationButtons = FALSE
  # parallelism = "clustermq",
  # jobs = 16
)


# Best fit layer kls  -----------------------------------------------------
path_sims3 <- here::here("03processed-data/bestfitLayerkl/")
path_layerkl <- here::here("05figures/kl_LayerByLayerCalibrationEDA/")
source(file.path(kRpath, "EditApsimxCalibrateLayers.R"))

source(file.path(kRpath, "plan_bestfitlayerkl.R"))

vis_drake_graph(
  plan_bestfitlayerkl, targets_only = TRUE
)


drake::make(plan_bestfitlayerkl, lock_envir = F, memory_strategy = "autoclean", 
            garbage_collection = TRUE)

