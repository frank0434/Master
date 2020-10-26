
drake::clean(destroy = TRUE)
#configurations
path_richard = "c:/Users/cflfcl/Dropbox/Data/APSIM_Sim.xlsx"
kRpath <- here::here("02Scripts/R")
path_EDAfigures <- here::here("05figures/klEDA/")
path_apsimx <- "C:/Data/ApsimX/ApsimXLatest/Bin/Models.exe"
path_lincoln <- here::here("01Data/ClimateAndObserved/lincoln.met")
path_AD <- here::here("01Data/ClimateAndObserved/AshleyDene.met")

# Environmental variables to control file paths
Sys.setenv("WorkingDir" = here::here("01Data/"))
Sys.setenv("BaseApsimxDir" = file.path(Sys.getenv("WorkingDir"), "ApsimxFiles/"))
Sys.setenv("MetDir" = file.path(Sys.getenv("WorkingDir"), "ClimateAndObserved/"))
Sys.setenv("ConfigFileDir" = file.path(Sys.getenv("WorkingDir"), "ProcessedData/ConfigurationFiles/"))
Sys.setenv("CoverDataDir" = file.path(Sys.getenv("WorkingDir"), "ProcessedData/CoverData/"))
Sys.setenv("SimsDir" = file.path(Sys.getenv("WorkingDir"), "ProcessedData/apsimxFiles/"))

#plan 
source(file.path(kRpath, "functions.R"))
source(file.path(kRpath, "packages.R"))

source(file.path(kRpath, "EditApsimx.R"))
source(file.path(kRpath, "plan.R"))
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


