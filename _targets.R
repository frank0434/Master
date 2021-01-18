library(targets)
# library(future)
# plan(multisession)
# Source functions

source("02Scripts/R/packages.R")
source("02Scripts/R/functions.R")
# Set constants 
path_richard <- "C:/Users/cflfcl/Dropbox/Data/APSIM_Sim.xlsx"
path_BD <- here::here("01Data/BulkDensity.xlsx")
dir_met <- here::here("01Data/ClimateAndObserved")
dir_cover <- here::here("01Data/ProcessedData/CoverData")
dir_config <- here::here("01Data/ProcessedData/ConfigurationFiles/")


path_lincoln <- here::here("01Data/ClimateAndObserved/lincoln.met")
path_AD <- here::here("01Data/ClimateAndObserved/AshleyDene.met")

# Set target-specific options such as packages.
tar_option_set(packages = c("data.table", "magrittr", "readxl", "openxlsx",
                            "ggplot2", "here", "autoapsimx", "sensitivity"))



# Define targets
targets <- list(
  # Define keys and treatments
  tar_target(Sites, unique(CoverData$Experiment)),
  tar_target(SD, unique(CoverData$SowingDate)),
  tar_target(No.ofLayers, seq(1, 22)),
  tar_target(parameters,  c("BD1","DUL1","LL1","SKL","KLR","RFV")),
  tar_target(id_vars, c("Experiment", "SowingDate", "Clock.Today")),
  tar_target(value_vars, grep("SW\\(\\d.+", colnames(data_SW), value = TRUE)),

  # Read data
  tar_target(data_SW, read_Sims(path = path_richard)),
  tar_target(sowingDates, read_Sims(path_richard, source =  "sowingDate")),
  tar_target(LAI_Height,  read_Sims(path = path_richard, source = "biomass")),
  tar_target(met_AshleyDene, read_met(path_AD, skip_unit = 10, skip_meta = 8)),
  tar_target(met_Iversen12, read_met(path_lincoln, skip_unit = 8, skip_meta = 6,
                                     site = "Iversen12")),
  tar_target(BDs, as.data.table(read_excel(path = path_BD))),
  tar_target(template, readLines(dir_tempalte)),
  
  # Do calculation
  tar_target(SW_mean, colwise_meanSW(data_SW = data_SW, id.vars = id_vars, col.vars = value_vars)),
  
  tar_target(cumTT, rbindlist(list(met_Iversen12, met_AshleyDene),
                              use.names = TRUE)[,.(Experiment, Clock.Today, AccumTT)]),
  tar_target(CoverData, interp_LAI(biomass = LAI_Height, sowingDates, cumTT)),
  
  tar_target(SW_initials, initialSWC(SW_mean, sowingDates, id_vars))
  # Output apsimx input and observed
  # tar_target(observed_LAI, outputLAIobserved(biomass = LAI_Height,
  #                                        Sites, SD,
  #                                        output = dir_cover), 
  #            format = "file", 
  #            pattern = cross(Sites, SD), 
  #            cue = tar_cue(depend = TRUE)),
  # tar_target(observed_SW, outputSWobserved(SW = SW_mean,
  #                                        Sites, SD,
  #                                        output = dir_cover), 
  #            format = "file", 
  #            pattern = cross(Sites, SD), 
  #            cue = tar_cue(depend = TRUE)),
  # 
  # tar_target(LAI_input, outputLAIinput(CoverData, Sites, SD, 
  #                                     output = dir_cover),
  #            format = "file", 
  #            pattern = cross(Sites, SD), 
  #            cue = tar_cue(depend = TRUE)),
  # tar_target(DUL_LL_range, doDUL_LL_range(SW = data_SW, id.vars = id_vars,
  #                                         value.vars = value_vars)),
  # # Build parameters for testing their sensitivity
  # tar_target(params_ranges, build_params(params = parameters, 
  #                                        Site = Sites, 
  #                                        SDs = SD, 
  #                                        Layer = No.ofLayers, 
  #                                        DT = DUL_LL_range, 
  #                                        blukdensity = BDs),
  #            pattern = cross(Sites, SD, No.ofLayers)),
  # # Build the morris models
  # tar_target(MorrisModels, build_models(params = parameters,paths = 100,
  #                                       para.low = params_ranges[[1]], 
  #                                       para.high = params_ranges[[2]],
  #                                       meta = names(params_ranges)),
  #            pattern = map(params_ranges)),
  # tar_target(sampledvalues, extract_samples(MorrisModels),
  #            pattern = map(MorrisModels)),
  # tar_target(apsimxPhase1, build_config(template = template, 
  #                                 dir_metfile = dir_met,
  #                                 dir_cover = dir_cover,
  #                                 dir_config = dir_config,
  #                                 dir_Sensitivity = dir_Sensitivity,
  #                                 apsimx = path_apsimx, 
  #                                 apsimx_Basefile = apsimx_Basefile,
  #                                 Site = Sites, SD = SD,
  #                                 DUL_LL_range = DUL_LL_range, 
  #                                 bulkDensity = BDs,
  #                                 SowingDates = sowingDates,
  #                                 SW_initial = SW_initials
  #                                 ), 
  #            format = "file", cue = tar_cue(mode = "always"),
  #            pattern = cross(Sites, SD))
  # 
  
)

# End with a call to tar_pipeline() to wrangle the targets together.
# This target script must return a pipeline object.
# tar_pipeline(targets)

