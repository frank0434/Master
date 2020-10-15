# plan.R
plan_config <- drake::drake_plan(
  # Data input
  water = read_Sims(path_richard),
  value_vars = grep("SW\\(\\d.+", colnames(water), value = TRUE),
  
  climate_units = read_met_col(here::here("Data/ClimateAndObserved/lincoln.met"), skip = 6),
  
  met_Iversen12 = read_met(here::here("Data/ClimateAndObserved/lincoln.met"), 
                           skip_unit =  7, skip_meta = 6
                           )[, Clock.Today := as.Date(day, origin = paste0(year, "-01-01"))
                             ][Clock.Today > "2010-10-01" & Clock.Today < "2012-08-01"
                               ][, AccumTT := cumsum(mean)
                                 ][, Experiment := "Iversen12"],
  
  met_AshleyDene = read_met(here::here("Data/ClimateAndObserved/AshleyDene.met"), 
                            skip_unit = 10, skip_meta = 8
                            )[, Clock.Today := as.Date(day, origin = paste0(year, "-01-01"))
                              ][Clock.Today > "2010-10-01" & Clock.Today < "2012-08-01"
                                ][, AccumTT := cumsum(mean)
                                  ][, Experiment:="AshleyDene"],
  
  
  # Transformation
  SWC_mean = water[,lapply(.SD, mean, na.rm = TRUE), 
                   by = id_vars, 
                   .SDcols = "SWC"],
  # mean divided by 100 to have vwc
  SW_mean = water[, lapply(.SD, function(x) mean(x, na.rm = TRUE)/100), 
                           by = id_vars,
                           .SDcols = value_vars],
  sowingDates = read_Sims(path_richard, source =  "sowingDate"), 
  ## SowingDate

  # Joinning for initial soil water conditions 
  SW_initials = initialSWC(SW_mean, sowingDates, id_vars),
  
  # DUL AND LL 
  DUL_LL = doDUL_LL(SW_mean, value_vars),

  # Joinning all 
  SW_DUL_LL = SW_initials[DUL_LL, 
                          on = c("Experiment", "SowingDate", "Depth")
                          ][,':='(Depth = as.integer(gsub("\\D", "", Depth)))
                            ][order(Experiment,SowingDate, Depth, Clock.Today)],
  
  # kl ----------------------------------------------------------------------
  ## Prepare the slurp model input 
  ## The canopy cover data is processed in a separate notebook
  ## SetUpCoverDataForSlurp
  CoverData = target(
    source_python(file_in("Scripts/Python/SetupCoverScript.py"),convert = FALSE),
    trigger = trigger(condition =  length(dir("Data/ProcessedData/CoverData/")) == 0,
                      mode = "condition")
    ),
  ## Prepare the configuration file and create multiple slurp simulations 
  # .2_Data_EDA_Part2_apsimxEdit.Rmd
  apsimxs = target(
    EditApsimx(SW_DUL_LL, sowingDates),
    trigger = trigger(condition =  length(dir("Data/ProcessedData/apsimxFiles/")) == 0,
                      mode = "condition"))
  
)

