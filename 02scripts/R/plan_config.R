# plan.R
plan_config <- drake::drake_plan(
  # Data input
  water = autoapsimx::read_dbtab(path = path_sql, 
                                 table = "SoilWater"),
  SowingDates = autoapsimx::read_dbtab(path = path_sql, 
                                       table = "SowingDates"),
  # Process data
  ## SoilWater
  # Actual measurements are 22 layers 
  water_22layers = rename_cols(DT = water[, `SW(2)`:=NULL]),
  value_vars = grep("SW\\(\\d.+", colnames(water_22layers), value = TRUE),
  SWC_mean = water[,lapply(.SD, mean, na.rm = TRUE), 
                   by = id_vars, 
                   .SDcols = "SWC"],
  # mean divided by 100 to have vwc
  SW_mean = water_22layers[, lapply(.SD, function(x) mean(x, na.rm = TRUE)/100), 
                           by = id_vars,
                           .SDcols = value_vars],
  ## SowingDate
  SD = SowingDates[, (c("AD", "I12")) := lapply(.SD, as.Date), 
                   .SDcols = c("AD", "I12")] %>% 
    data.table::melt(id.vars = "SD", 
                     variable.name = "Experiment", value.name = "Clock.Today",
                     variable.factor = FALSE) ,
  SD_tidied = SD[, Experiment := ifelse(Experiment == "AD", 
                                        "AshleyDene",  
                                        "Iversen12")],
  # Joinning for initial soil water conditions 
  SW_initials = SW_mean[SD_tidied, 
                        on = c("Experiment", "SowingDate == SD", "Clock.Today"),
                        roll = "nearest"],
  SW_initials_tidied = data.table::melt(
    SW_initials, 
    id.vars = id_vars, 
    variable.factor = FALSE,
    variable.name = "Depth",
    value.name = "SW"
  )[, ':='(SW = round(SW, digits = 3))],
  # DUL AND LL 
  DUL_LL = SW_mean[, unlist(lapply(.SD, max_min), recursive = FALSE), 
                   by = .(Experiment, SowingDate), .SDcols = value_vars],
  # Tidy up DUL AND LL
  melted_DUL_LL = data.table::melt(DUL_LL, 
                                   id.var = c("Experiment","SowingDate"), 
                                   variable.factor = FALSE),
  DUL_LL_SDs = melted_DUL_LL[, 
                             (c("Depth", "variable")) := tstrsplit(variable, "\\.")] %>% 
    data.table::dcast(Experiment +  SowingDate + Depth ~ variable),
  
  DUL_LL_SDsVWC = DUL_LL_SDs[, ':='(DUL = round(DUL, digits = 3),
                                    LL = round(LL, digits = 3))
                             ][, PAWC := DUL - LL],
  # Joinning all 
  SW_DUL_LL = SW_initials_tidied[DUL_LL_SDsVWC, 
                                 on = c("Experiment", "SowingDate", "Depth")
                                 ][,':='(Depth = as.integer(gsub("\\D", "", Depth)))
                                     ][order(Experiment,SowingDate, Depth, Clock.Today)],
  
  
  # kl ----------------------------------------------------------------------
  ## Prepare the slurp model input 
  ## The canopy cover data is processed in a separate notebook
  ## SetUpCoverDataForSlurp
  CoverData = target(
    source_python(file_in("02scripts/Python/SetupCoverScript.py"),convert = FALSE),
    trigger = trigger(condition =  length(dir("./03processed-data/CoverData/")) == 0,
                      mode = "blacklist")
    ),
  ## Prepare the configuration file and create multiple slurp simulations 
  # .2_Data_EDA_Part2_apsimxEdit.Rmd
  apsimxs = target(
    EditApsimx(SW_DUL_LL, SD_tidied),
    trigger = trigger(condition =  length(dir("./03processed-data/apsimxFiles/")) == 0,
                      mode = "blacklist")
  )
)