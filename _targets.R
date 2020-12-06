library(targets)
library(future)
# plan(multisession)
# Source functions
invisible(lapply(list.files("R/functions/", pattern = "R", full.names = TRUE),
                 source))
source("R/packages.R")
# Set constants 
path_richard <- "C:/Users/cflfcl/Dropbox/Data/APSIM_Sim.xlsx"
path_apsimx <- "C:/Data/ApsimX/ApsimXLatest/Bin/Models.exe"
path_BD <- here::here("Data/BulkDensity.xlsx")
dir_tempalte <- here::here("Data/ApsimxFiles/SlurpTemplateFirstPhase.txt")
dir_tempalte2 <- here::here("Data/ApsimxFiles/SlurpTemplateSecondPhase.txt")
dir_met <- here::here("Data/ClimateAndObserved")
dir_cover <- here::here("Data/ProcessedData/CoverData")
dir_config <- here::here("Data/ProcessedData/ConfigurationFiles/")
dir_simulations <- here::here("Data/ProcessedData/apsimxFiles/")

## The flag
apsimx_flag <- "/Edit"
## The base apsimx file 
apsimx_Basefile <- here::here("Data/ApsimxFiles/20200517BaseSlurp.apsimx")
path_lincoln <- here::here("Data/ClimateAndObserved/lincoln.met")
path_AD <- here::here("Data/ClimateAndObserved/AshleyDene.met")

# Set target-specific options such as packages.
tar_option_set(packages = c("data.table", "magrittr", "readxl", "openxlsx",
                            "ggplot2", "here", "autoapsimx", "sensitivity"))

# Define targets
targets <- list(
  # Define keys and treatments
  tar_target(Sites, unique(CoverData$Experiment)),
  tar_target(SD, unique(CoverData$SowingDate)),
  tar_target(id_vars, c("Experiment", "SowingDate", "Clock.Today")),
  tar_target(value_vars, grep("SWmm\\.\\d.", colnames(data_SW), value = TRUE)),
  tar_target(SKL_Range, seq(0.005, 0.11, by = 0.005)),
  # Read data
  tar_target(data_SW, read_Sims(path = path_richard)),
  tar_target(sowingDates, read_Sims(path_richard, source =  "sowingDate")),
  tar_target(LAI_Height,  read_Sims(path = path_richard, source = "biomass")),
  tar_target(met_AshleyDene, read_met(path_AD, skip_unit = 10, skip_meta = 8)),
  tar_target(met_Iversen12, read_met(path_lincoln, skip_unit = 8, skip_meta = 6,
                                     site = "Iversen12")),
  tar_target(BDs, as.data.table(read_excel(path = path_BD))),
  tar_target(template, readLines(dir_tempalte)),
  tar_target(templatePhase2, readLines(dir_tempalte2)),
  # Do calculation
  tar_target(SW_mean, colwise_meanSW(data_SW = data_SW, 
                                     id.vars = id_vars, 
                                     col.vars = value_vars)),
  
  tar_target(cumTT, rbindlist(list(met_Iversen12, met_AshleyDene),
                              use.names = TRUE)[,.(Experiment, Clock.Today, AccumTT)]),
  tar_target(CoverData, interp_LAI(biomass = LAI_Height, sowingDates, cumTT)),
  
  tar_target(SW_initials, initialSWC(SW_mean, sowingDates, id_vars)),
  # Output apsimx input and observed
  tar_target(observed, outputobserved(biomass = LAI_Height,
                                      SW = SW_mean, 
                                      site = Sites,SD = SD,
                                      output = dir_cover), 
             format = "file", 
             pattern = cross(Sites, SD), 
             cue = tar_cue(depend = TRUE)),
  
  tar_target(LAI_input, outputLAIinput(CoverData, Sites, SD, 
                                      output = dir_cover),
             format = "file", 
             pattern = cross(Sites, SD), 
             cue = tar_cue(depend = TRUE)),
  tar_target(DUL_LL_range, doDUL_LL_range(SW = data_SW, id.vars = id_vars,
                                          value.vars = value_vars)),
  # Build the apsimx 
  tar_target(apsimxPhase1, build_apsimx(template = template,
                                        dir_metfile = dir_met,
                                        cover = LAI_input,
                                        observed = observed,
                                        dir_simulations = dir_simulations ,
                                        dir_config = dir_config,
                                        apsimx = path_apsimx,
                                        apsimx_Basefile = apsimx_Basefile,
                                        DUL_LL_range = DUL_LL_range,
                                        bulkDensity = BDs,
                                        SowingDates = sowingDates,
                                        SW_initial = SW_initials
                                  ),
             format = "file",
             cue = tar_cue(file = TRUE),
             pattern =  map(LAI_input,observed)),
  tar_target(apsimxPhase2, build_optimSlurp(template = templatePhase2,
                                            dir_optim = dir_simulations,
                                            dir_config = dir_config,
                                            KL_range = SKL_Range,
                                            apsimx = path_apsimx,
                                            apsimx_Basefile = apsimxPhase1
                                            ),
             cue = tar_cue(mode = "never"),
             pattern =  map(apsimxPhase1))
  
  
)

# End with a call to tar_pipeline() to wrangle the targets together.
# This target script must return a pipeline object.
tar_pipeline(targets)

