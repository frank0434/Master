# This plan is using the assumption that the kl values decay expotentially by
# depth

plan_SW <- drake::drake_plan(
  water = autoapsimx::read_dbtab(path = path_sql, 
                                 table = "SoilWater"),
  SowingDates = autoapsimx::read_dbtab(path = path_sql, 
                                       table = "SowingDates"),
  
  water_22layers = rename_cols(DT = water[, `SW(2)`:=NULL]),
  value_vars = grep("SW\\(\\d.+", colnames(water_22layers), value = TRUE),
  SW_mean = water_22layers[, lapply(.SD, function(x) mean(x, na.rm = TRUE)/100), 
                           by = id_vars,
                           .SDcols = value_vars],
  
  l_stats_SW = autoapsimx::sims_stats_multi(path_sims = path_sims,
                                            DT_observation = SW_mean,
                                            mode = "Layers",
                                            keys = stats_key_SW),
  DT_stats_SW = data.table::rbindlist(l_stats_SW),
  top5_stats_SW = DT_stats_SW[, unlist(stats, recursive = FALSE),
                              by = stats_key_SW
                              ][NSE > 0 # Pointless to have NSE value less than 0
                                ][order(NSE,R2, RMSE, decreasing = TRUE),
                                  index := seq_len(.N),
                                  by = list(Experiment, SowingDate, Depth)
                                  ][index < 2][, index := NULL],
  DT_stats_sub_SW = DT_stats_SW[top5_stats_SW,
                                on = stats_key_SW],
  top5_SW = DT_stats_sub_SW[, unlist(data, recursive = FALSE),
                            by = stats_key_SW_extra],
  Site_SD = target(
    autoapsimx::subset_pred(DT = top5_SW, 
                            treatment1 = sites ,
                            treatment2 = sds),
    transform = cross(sites = c("AshleyDene", "Iversen12"),
                      sds = c("SD1",  "SD2", "SD3",  "SD4",  "SD5",
                              "SD6",  "SD7",  "SD8",  "SD9",  "SD10"))
  ),
  plot_SW = target(
    plot_params(DT = Site_SD, 
                col_pred = "pred_VWC", col_obs = "ob_VWC",
                Depth = "Depth",
                height = 16, width = 20,
                title = file_out(!!paste0(path_EDAfigures,"/",.id_chr))),
    transform = map(Site_SD),
    trigger = trigger(condition = TRUE, mode = "blacklist")
  )
)