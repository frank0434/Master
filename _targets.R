library(targets)

# Source functions
source("R/functions.R")
source("R/packages.R")
# Set constants 
path_richard <- "C:/Users/cflfcl/Dropbox/Data/APSIM_Sim.xlsx"
path_apsimx <- "C:/Data/ApsimX/ApsimXLatest/Bin/Models.exe"
path_lincoln <- here::here("Data/ClimateAndObserved/lincoln.met")
path_AD <- here::here("Data/ClimateAndObserved/AshleyDene.met")

Sys.setenv("WorkingDir" = 
             here::here("Data/"))
Sys.setenv("BaseApsimxDir" = 
             file.path(Sys.getenv("WorkingDir"), "ApsimxFiles/"))
Sys.setenv("MetDir" = 
             file.path(Sys.getenv("WorkingDir"), "ClimateAndObserved/"))
Sys.setenv("ConfigFileDir" = 
             file.path(Sys.getenv("WorkingDir"), "ProcessedData/ConfigurationFiles/"))
Sys.setenv("CoverDataDir" = 
             file.path(Sys.getenv("WorkingDir"), "ProcessedData/CoverData/"))
Sys.setenv("SimsDir" = 
             file.path(Sys.getenv("WorkingDir"), "ProcessedData/apsimxFiles/"))

# Set target-specific options such as packages.
tar_option_set(packages = c("data.table", "magrittr", "readxl", 
                            "ggplot2", "here", "autoapsimx"))


# Define targets
targets <- list(
  # Define keys and treatments
  tar_target(Sites, unique(CoverData$Experiment)),
  tar_target(SD, unique(CoverData$SowingDate)),
  tar_target(id_vars, c("Experiment", "SowingDate", "Clock.Today")),
  tar_target(value_vars, grep("SW\\(\\d.+", colnames(data_SW), value = TRUE)),
  
  # Read data
  tar_target(data_SW, read_Sims(path = path_richard)),
  tar_target(sowingDates, read_Sims(path_richard, source =  "sowingDate")),
  tar_target(LAI_Height,  read_Sims(path = path_richard, source = "biomass")),
  tar_target(met_AshleyDene, read_met(path_AD, skip_unit = 10, skip_meta = 8)),
  tar_target(met_Iversen12, read_met(path_lincoln, skip_unit = 8, skip_meta = 6,
                                     site = "Iversen12")),
  
  # Do calculation
  tar_target(SW_mean, colwise_meanSW(data_SW = data_SW, id.vars = id_vars, col.vars = value_vars)),
  
  tar_target(cumTT, rbindlist(list(met_Iversen12, met_AshleyDene),
                              use.names = TRUE)[,.(Experiment, Clock.Today, AccumTT)]),
  tar_target(CoverData, interp_LAI(biomass = LAI_Height, sowingDates, cumTT)),
  
  tar_target(SW_initials, initialSWC(SW_mean, sowingDates, id_vars)),
  # Output apsimx input and observed
  tar_target(observed_LAI, outputLAIobserved(biomass = LAI_Height,
                                         Sites, SD,
                                         output = Sys.getenv("CoverDataDir")), 
             format = "file", 
             pattern = cross(Sites, SD), 
             cue = tar_cue(depend = TRUE)),
  tar_target(observed_SW, outputSWobserved(SW = SW_mean,
                                         Sites, SD,
                                         output = Sys.getenv("CoverDataDir")), 
             format = "file", 
             pattern = cross(Sites, SD), 
             cue = tar_cue(depend = TRUE)),
  
  tar_target(LAI_input, outputLAIinput(CoverData, Sites, SD, 
                                      output = Sys.getenv("CoverDataDir")),
             format = "file", 
             pattern = cross(Sites, SD), 
             cue = tar_cue(depend = TRUE)),
  tar_target(DUL_LL_range, doDUL_LL_range(SW = data_SW, id.vars = id_vars,
                                          value.vars = value_vars))
)

# End with a call to tar_pipeline() to wrangle the targets together.
# This target script must return a pipeline object.
tar_pipeline(targets)

