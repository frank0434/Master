

## Source functions
invisible(lapply(list.files("02Scripts/R/functions/", pattern = "R", full.names = TRUE),
                 source))
source("02Scripts/R/packages.R")
source("02Scripts/R/functions.R")
# plan(callr)

# If use job scheduler 
REMOTE = TRUE

if(REMOTE){
  # Set cluster 
  plan(batchtools_lsf,template='./openlava_batchtools.tmpl')
  
  # So we can Access LSF 
  RLinuxModules::module('load openlava') 
  
  tar_option_set(deployment="main",  # default to host
                 packages = c("data.table", "here", "magrittr","readxl", "RSQLite","DBI",
                              "openxlsx", "autoapsimx", "DEoptim"), 
                 library = here::here("renv/library/R-4.0/x86_64-pc-linux-gnu/")
                 # imports = c("package1", "package2")
                 )
  keypath <- here::here("01Data/APSIM_Sim.xlsx")
} else{
  keypath <- here::here("~/Dropbox/Data/APSIM_Sim.xlsx")
  
}


# Construct the instruction
values <-  data.table::data.table(Site = c("AshleyDene","Iversen12"),
                                  SowingDate = rep(paste0("SD", 1:2), each = 2))
# Raw data path
targets0 <- list(
  tar_target(path_richard, keypath),
  # Constants raw data
  tar_target(rawobs, read_excel(path_richard, 
                     guess_max = 10300, sheet = 2,
                     skip = 9, .name_repair = "universal") %>% 
  as.data.table()),
  tar_target(params, read_excel(here("01Data/SlurpParamList.xlsx")) %>% 
               as.data.table(), cue = tar_cue(mode = "always")),
  # Get SWC data and filter down to the required sown dates
  tar_target(data_SW, as.data.table(read_Sims(path = path_richard))),
  
  # Constant variables
  tar_target(id_vars, c("Experiment", "SowingDate", "Clock.Today", "DAS")),
  tar_target(value_vars, grep("SWmm\\.\\d.", colnames(data_SW), value = TRUE)),
  # Date for reset soil water content
  tar_target(magicDate, as.Date("2011-06-25")),
  # Get the actual dates of sowing
  tar_target(sowingDates, read_Sims(path_richard, source =  "sowingDate")),
  # Modify SD1:5 to magic dates for reset initial swc in the second season
  tar_target(resetDates, sowingDates[SowingDate%in% paste0("SD", 1:5), 
                                     Clock.Today := as.Date(magicDate)]),
  # Get the LAI for daily value interpolation 
  tar_target(LAI_Height,  read_Sims(path = path_richard, source = "biomass")),
  
  # APSIMX constants
  tar_target(path_apsimx, 
             "C:/Data/ApsimX/ApsimXLatest/Bin/Models.exe"),
  tar_target(template,
             readLines(here::here("01Data/ApsimxFiles/SlurpTemplate.txt")),
             cue = tar_cue(mode = "always")),
  tar_target(apsimx_Basefile,
             here::here("01Data/ApsimxFiles/SingleSlurp.apsimx")),
  # tar_target(obs_para, "SWCmm"),
  tar_target(parameters, prepare_params(params = params)),
  tar_target(par, parameters$initials),
  tar_target(apsimx_sims_dir, here("01Data/ProcessedData/apsimxFiles"))
)

targets1 <- tar_map(
  values = values, 
  names = c("Site", "SowingDate"),
  # Constants
  tar_target(SD, SowingDate),
  tar_target(Sites, Site),
  
  # Site depended targets
  tar_target(path_met, ifelse(Sites == "AshleyDene", 
                              here::here("01Data/ClimateAndObserved/AshleyDene.met"),
                              here::here("01Data/ClimateAndObserved/Iversen12.met"))),
  tar_target(lucerne_height, ifelse(Sites == "AshleyDene", 390L, 595L)),
  tar_target(met, read_met(path_met)),
  
  tar_target(BD, filter_BD(path = here("01Data/BulkDensity.xlsx"), Sites)),
  # Site and Sowing dates depended targets 
  tar_target(SimName, paste0(Sites, "SowingDate", SD)),
  ## Observations
  tar_target(obs, prepare_obs(rawobs, trts = c(Sites, SD))),
  tar_target(cumTT, met[,.(Experiment, Clock.Today, AccumTT)]),
  tar_target(actualSD, filter_SD(sowingDates, trts = c(Sites, SD))),
  tar_target(resetSD, filter_SD(resetDates, trts = c(Sites, SD))),
  tar_target(CoverData, interp_LAI(biomass = LAI_Height,
                                   sowingDates = actualSD, 
                                   accumTT =  met[,.(Experiment, Clock.Today, AccumTT)], 
                                   trts = c(Sites, SD))),
  # Subset the raw sw into treatment level
  tar_target(SW, filter_SW(data_SW, trts = c(Sites, SD))), 
  tar_target(SW_sub, colwise_meanSW(DT = SW,
                                     id.vars = id_vars,
                                     col.vars = value_vars)),
  tar_target(SW_initials, initialSWC(SW_sub, sowingDates = actualSD, id_vars)),
  tar_target(SW_initials_reset, initialSWC(SW_sub, sowingDates = resetSD, id_vars)),
  tar_target(DUL_LL_range, doDUL_LL_range(SW = SW_sub,
                                          id.vars = id_vars)),
  # Manually adjust the DUL levels to 0.95
  tar_target(DUL_LL_range_arbitrary, DUL_LL_range[,':='(SAT = SW.DUL* 1.05,
                                                        SW.DUL = SW.DUL * 0.95,
                                                        SW.LL15 = SW.LL * 0.95)]),
  # Combine all into one list
  tar_target(input_list, combine_input( SimName,
                                        obs, 
                                        actualSD,
                                        path_met, #climate met path 
                                        CoverData, 
                                        lucerne_height, # sowing dates
                                        BD,
                                        SW_initials,
                                        DUL_LL_range_arbitrary,
                                        resetSD,
                                        SW_initials_reset
                                        )),
  # Construct the configuration file 
  tar_target(opt.res,
             wrapper_deoptim(parameters = parameters,
                             par = parameters$initials,
                             # obspara =  "SWCmm",
                             maxIt = 3,
                             np = length(par),
                             Sites, SD,
                             template,
                             path_apsimx,
                             magicDate,
                             apsimx_Basefile,
                             # obspara,
                             apsimx_sims_dir,
                             # APSIMEditFun,
                             # APSIMRun,
                             input_list),
             deployment = "main"
             )
)

list(targets0, targets1)
