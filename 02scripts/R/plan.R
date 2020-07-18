# plan.R
plan_analysis <- drake::drake_plan(
  # Data input
  water = autoapsimx::read_dbtab(path = path_sql, 
                                 table = "SoilWater"),
  # SowingDates = autoapsimx::read_dbtab(path = path_sql, 
  #                                      table = "SowingDates"),
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
  
  # kl ----------------------------------------------------------------------
  ## Prepare the slurp model input 
  ## The canopy cover data is processed in a separate notebook
  ## SetUpCoverDataForSlurp
  # CoverData = source_python(file_in("02scripts/Python/SetupCoverScript.py"),convert = FALSE),
  ## Prepare the configuration file and create multiple slurp simulations 
  # .2_Data_EDA_Part2_apsimxEdit.Rmd

    ## Trigger the simulation run
  
  ## Analysis the simulation output 
  ## .2_Data_EDA_Part3_kl_estimation.Rmd
  
  ## Test
  # dt = read_dbtab(path = "03processed-data/apsimxFiles/ModifiedSKL_0.01AshleyDeneSD10.db",
  #                 table = "Report"),
  # site = extract_trts(filename = "03processed-data/apsimxFiles/ModifiedSKL_0.01AshleyDeneSD10.db")[1],
  # sd_filter = extract_trts(filename = "03processed-data/apsimxFiles/ModifiedSKL_0.01AshleyDeneSD10.db")[2],
  # obs_sd = SW_mean[Experiment == site & SowingDate == sd_filter],
  # pred_sw = manipulate(DT_obs = obs_sd, subset_cols = NULL, DT_pred = dt),
  # stats = sims_stats(pred_obs = pred_swc)
  
  ## SWC
  l_stats = autoapsimx::sims_stats_multi(file_in(!!path_sims), 
                                         DT_observation = SWC_mean,
                                         mode = "Profile"),
  DT_stats = data.table::rbindlist(l_stats),
  top5_stats = DT_stats[, unlist(stats, recursive = FALSE),
                        by = stats_key
                        ][NSE > 0 # Pointless to have NSE value less than 0
                          ][order(NSE,R2, RMSE, decreasing = TRUE),
                            index := seq_len(.N), 
                            by = list(Experiment, SowingDate)
                            ][index <= 1][, index := NULL],
  DT_stats_sub = DT_stats[top5_stats, 
                          on = stats_key],
  top5 = DT_stats_sub[, unlist(data, recursive = FALSE), 
                      by = stats_key_extra],
  Site_SD = target(
    autoapsimx::subsetByTreatment(DT = top5, mode = "prediction",
                            treatment1 = sites ,
                            treatment2 = sds),
    transform = cross(sites = c("AshleyDene", "Iversen12"),
                      sds = c("SD1",  "SD2", "SD3",  "SD4",  "SD5",
                              "SD6",  "SD7",  "SD8",  "SD9",  "SD10"))
  ),
  plot = target(
    plot_params(DT = Site_SD, file_out(!!paste0(path_EDAfigures,"/",.id_chr)), format = "png"),
    transform = map(Site_SD),
    trigger = trigger(condition = TRUE, mode = "blacklist")
  ), 

  
  ## SW layer
 
  obs_SW = target(
    autoapsimx::subsetByTreatment(DT = SW_mean, mode = "observation",
                           treatment1 = sites ,
                           treatment2 = sds),
    transform = cross(sites = c("AshleyDene", "Iversen12"),
                      sds = c("SD1",  "SD2", "SD3",  "SD4",  "SD5",
                              "SD6",  "SD7",  "SD8",  "SD9",  "SD10"))
    ),
  pred_SW = target(
    data.table::melt(Site_SD,
                     value.name = "pred_VWC",
                     measure.vars = value_vars,
                     variable.name = "Depth",
                     variable.factor = FALSE),
    transform = map(Site_SD)
  ),
  long = target(
    data.table::melt(obs_SW,
                     value.name = "obs_VWC",
                     measure.vars =value_vars,
                     variable.name = "Depth",
                     variable.factor = FALSE),
    transform = map(obs_SW)
  ),
  # Joining the prediction and observation for Soil water in each layer
  pred_obs = target(
    merge.data.table(pred_SW, long, 
                     by.x = c("Date", "Depth","Experiment", "SowingDate"), 
                     by.y = c("Clock.Today", "Depth","Experiment", "SowingDate"), 
                     all.x = TRUE )[, Depth := forcats::fct_relevel(as.factor(Depth), paste0("SW(",1:22, ")"))],
    transform = map(pred_SW, long)
  ),
  plot_Root = target(
    plot_root(DT = Site_SD, 
              title = file_out(!!paste0(path_EDAfigures,"/",
                                        gsub("pred_obs_pre_SW.+SW", 
                                             "" ,.id_chr))), 
              point_size = 5,
              height = 6, width = 9, format = "png"),
    transform = map(pred_obs),
    trigger = trigger(condition = TRUE, mode = "blacklist")
  ), 
  plot_SW = target(
    plot_params(DT = pred_obs, 
                col_pred = "pred_VWC", col_obs = "obs_VWC",
                Depth = "Depth",
                height = 16, width = 9,
                title = file_out(!!paste0(path_EDAfigures,"/",.id_chr)),format = "png"),
    transform = map(pred_obs),
    trigger = trigger(condition = TRUE, mode = "blacklist")
  ),
  best_fit = target(
    data.table::fwrite(top5[, list(Experiment, SowingDate, SimulationID, SKL,KLR, RFV, NSE, R2, RMSE)
                            ][order(NSE, R2,RMSE)
                              ][, .SD[1], by = .(Experiment, SowingDate)
                                ][, data:=NULL],
                       file_out(!!paste0(.id_chr, ".csv"))),
    transform = map(data = c(top5))
  )
  
)

