# plan.R
plan <- drake::drake_plan(
  # Data input
  water = autoapsimx::read_dbtab(path = path_sql, 
                                 table = "SoilWater"),
  SowingDates = autoapsimx::read_dbtab(path = path_sql, 
                                       table = "SowingDates"),
  # Process data
  ## SoilWater

  value_vars = grep("SW\\(\\d.+", colnames(water), value = TRUE),
  SWC_mean = water[,lapply(.SD, mean, na.rm = TRUE), 
                   by = id_vars, 
                   .SDcols = "SWC"],
  SW_mean = water[, lapply(.SD, mean, na.rm = TRUE), 
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
    )[, ':='(SW = round(SW / 100, digits = 3))],
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
  
  DUL_LL_SDsVWC = DUL_LL_SDs[, ':='(DUL = round(DUL/100, digits = 3),
                                     LL = round(LL/100, digits = 3))
                              ][, PAWC := DUL - LL],
  # Joinning all 
  SW_DUL_LL = SW_initials_tidied[DUL_LL_SDsVWC, 
                                 on = c("Experiment", "SowingDate", "Depth")
                                 ][Depth != "SW(2)"
                                   ][,':='(Depth = as.integer(gsub("\\D", "", Depth)))],
  
  # kl ----------------------------------------------------------------------
  ## Prepare the slurp model input 
  ## The canopy cover data is processed in a separate notebook
  ## SetUpCoverDataForSlurp
  
  ## Prepare the configuration file and create multiple slurp simulations 
  ## .2_Data_EDA_Part2_apsimxEdit.Rmd
  
  ## Trigger the simulation run
  
  ## Analysis the simulation output 
  ## .2_Data_EDA_Part3_kl_estimation.Rmd
  
  ## Test
  # dt = read_dbtab(path = "03processed-data/apsimxFiles/ModifiedSKL_0.01AshleyDeneSD10.db",
  #                 table = "Report"),
  # site = extract_trts(filename = "03processed-data/apsimxFiles/ModifiedSKL_0.01AshleyDeneSD10.db")[1],
  # sd_filter = extract_trts(filename = "03processed-data/apsimxFiles/ModifiedSKL_0.01AshleyDeneSD10.db")[2],
  # obs_sd = SWC_mean[Experiment == site & SowingDate == sd_filter],
  
  # pred_swc = manipulate(DT_obs = obs_sd, DT_pred = dt),
  # stats = sims_stats(pred_obs = pred_swc)
  
  l_stats = autoapsimx::sims_stats_multi(path_sims = path_sims, DT_observation = SWC_mean),
  DT_stats = data.table::rbindlist(l_stats),
  top5_stats = DT_stats[, unlist(stats, recursive = FALSE),
                        by = stats_key
                        ][NSE > 0 # Pointless to have NSE value less than 0
                          ][order(NSE,R2, RMSE, decreasing = TRUE),
                            index := seq_len(.N), 
                            by = list(Experiment, SowingDate)
                            ][index <= 5][, index := NULL],
  DT_stats_sub = DT_stats[top5_stats, 
                          on = stats_key],
  top5 = DT_stats_sub[, unlist(data, recursive = FALSE), 
                      by = stats_key_extra],
  Site_SD = target(
    autoapsimx::subset_toPlot(DT = top5, 
                              treatment1 = sites ,
                              treatment2 = sds),
    transform = cross(sites = c("AshleyDene", "Iversen12"),
                      sds = c("SD1",  "SD2", "SD3",  "SD4",  "SD5",
                              "SD6",  "SD7",  "SD8",  "SD9",  "SD10"))
  ),
  plot = target(
    plot_params(DT = Site_SD, file_out(!!paste0(path_EDAfigures,"/",.id_chr))),
    transform = map(Site_SD)
  )
)
