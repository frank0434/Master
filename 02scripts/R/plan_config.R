# plan.R
plan_config <- drake::drake_plan(
  # Data input
  water = autoapsimx::read_dbtab(path = path_sql, 
                                 table = "SoilWater"),
  SowingDates = autoapsimx::read_dbtab(path = path_sql, 
                                       table = "SowingDates"),
  preds = target(
    read_dbtab("./03processed-data/apsimxLucerne/BestfitLayerkl.db", table = "Report"),
    trigger = trigger(condition = TRUE)
    ), 
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
  # Subset
  configs = target(
    autoapsimx::subsetByTreatment(DT = SW_DUL_LL, 
                                  treatment1 = sites,
                                  treatment2 = sds),
    transform = cross(sites = c("AshleyDene", "Iversen12"),
                      sds = c("SD1",  "SD2", "SD3",  "SD4",  "SD5",
                              "SD6",  "SD7",  "SD8",  "SD9",  "SD10"))
  ),
  
  
  # Subset observation data ----------------------------------------------------------------------
  ## k and LAI
  CoverData = target(
    source_python(file_in("02scripts/Python/SetupCoverScript.py"),convert = FALSE),
    trigger = trigger(condition =  length(dir("./03processed-data/CoverData/")) == 0,
                      mode = "blacklist")
    ),
  ## SW 
  obs_SW = target(
    autoapsimx::subsetByTreatment(DT = SW_mean, 
                                  treatment1 = sites,
                                  treatment2 = sds),
    transform = cross(sites = c("AshleyDene", "Iversen12"),
                      sds = c("SD1",  "SD2", "SD3",  "SD4",  "SD5",
                              "SD6",  "SD7",  "SD8",  "SD9",  "SD10"))
  ),
  ## SWC
  obs_SWC = target(
    autoapsimx::subsetByTreatment(DT = SWC_mean, 
                                  treatment1 = sites ,
                                  treatment2 = sds),
    transform = cross(sites = c("AshleyDene", "Iversen12"),
                      sds = c("SD1",  "SD2", "SD3",  "SD4",  "SD5",
                              "SD6",  "SD7",  "SD8",  "SD9",  "SD10"))
  ),
  ## SW_long 
  obs_long = target(
    data.table::melt(obs_SW,
                     value.name = "obs_VWC",
                     measure.vars = value_vars, 
                     variable.name = "Depth",
                     variable.factor = FALSE),
    transform = map(obs_SW)
  ),
  preds_long = target(
    data.table::melt(prediction,
                     value.name = "preds_VWC",
                     measure.vars = value_vars, 
                     variable.name = "Depth",
                     variable.factor = FALSE),
    transform = map(prediction),
    trigger = trigger(condition = TRUE)
  ),
  ## SWC 
  prediction = target(
    autoapsimx::subsetByTreatment(DT = preds, 
                                  treatment1 = sites ,
                                  treatment2 = sds),
    transform = cross(sites = c("AshleyDene", "Iversen12"),
                      sds = c("SD1",  "SD2", "SD3",  "SD4",  "SD5",
                              "SD6",  "SD7",  "SD8",  "SD9",  "SD10")),
    trigger = trigger(condition = TRUE)
  ), 
  joined_SWC = target(
    merge.data.table(prediction[,list(Date, Experiment, SowingDate, PSWC)], obs_SWC, all.x = TRUE, 
                     by.x = c("Date", "Experiment", "SowingDate"),
                     by.y = c("Clock.Today", "Experiment", "SowingDate")),
    transform = map(prediction, obs_SWC),
    trigger = trigger(condition = TRUE)
  ),
  
  joined_SW = target(
    merge.data.table(preds_long, obs_long, all.x = TRUE, 
                     by.x = c("Date", "Experiment","SowingDate", "Depth"),
                     by.y = c("Clock.Today", "Experiment", "SowingDate", "Depth")),
    transform = map(preds_long, obs_long),
    trigger = trigger(condition = TRUE)
  ),
  plot_SW = target(
    plot_params(DT = joined_SW[, Depth := forcats::fct_relevel(as.factor(Depth), 
                                                              paste0("SW(",1:22, ")"))], 
                col_pred = "preds_VWC", col_obs = "obs_VWC",
                stats = FALSE,
                Depth = "Depth", group_params = ".",
                height = 16, width = 9,
                title = file_out(!!paste0(path_EDAfigures,"/",
                                          gsub("joined_SW_preds_long_prediction_(AshleyDene|Iversen12)_SD\\d{1,2}_obs_long_obs_SW", 
                                               "", .id_chr))),format = "png"),
    transform = map(joined_SW),
    trigger = trigger(condition = TRUE, mode = "blacklist")
  ),
  plot_SWC = target(
    plot_params(DT = joined_SWC, 
                col_pred = "PSWC", 
                col_obs = "SWC",
                group_params = "Experiment",
                stats = FALSE, height = 4.1,
                title = file_out(!!paste0(path_EDAfigures,"/",
                                          gsub("joined_SWC_prediction_(AshleyDene|Iversen12)_SD\\d{1,2}_obs_SWC", 
                                               "", .id_chr))),format = "png"),
    transform = map(joined_SWC),
    trigger = trigger(condition = TRUE, mode = "blacklist")
  )
  
)
