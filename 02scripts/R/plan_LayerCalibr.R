# plan.R
plan_LayerCalibr <- drake::drake_plan(
  # Data input
  best_fit = readd(top5)[, list(data = list(.SD)), 
                         by = .(Experiment, SowingDate, SimulationID, SKL,KLR, RFV, NSE, R2, RMSE)
                         ][order(NSE, R2,RMSE)
                           ][, .SD[1], by = .(Experiment, SowingDate)],
  info = best_fit[,.(Experiment, SowingDate, SimulationID, SKL, KLR,RFV)],

  best_files = lapply(seq(1, nrow(info)), function(x){
    orig = here::here("03processed-data/apsimxFiles/")
    basename = paste0("ModifiedSKL_", 
                      info[x, ][["SKL"]],
                      info[x, ][["Experiment"]], 
                      info[x, ][["SowingDate"]], ".db")
    file = file.path(orig, basename)
    dt = read_dbtab(file, "SummaryNumbers")
    dt[, ':='(Experiment = info[x, ][["Experiment"]],
              SowingDate = info[x, ][["SowingDate"]],
              SKL = info[x, ][["SKL"]])]
    
    dt = dt[SimulationID == info[x, ][["SimulationID"]]]
  }), 
  kls = process_list(best_files), 
  ## Prepare the configuration file and create multiple slurp simulations 
  # .2_Data_EDA_Part2_apsimxEdit.Rmd
  # Set up initial condtions 
  apsimxs = target(
    EditApsimxLayers(apsimx, info, readd(SW_DUL_LL), readd(SD_tidied), kls),
    trigger = trigger(condition =  TRUE ,mode = "blacklist")
  ),

  files = list.files(here::here("03processed-data/apsimxFilesLayers/"), 
                     pattern = "^Layer.+.apsimx$", full.names = TRUE)
  # Edit layer from 2 and below
  # apsimxlayerkl = target(
  #   EditLayerKL_multi(KL_layers , KL_range, path =  apsimx,
  #                     files = files[1:18],
  #                     saveTo = path_sims2),
  #   trigger = trigger(condition =  FALSE,mode = "blacklist"),
  # ),
  # closeDBconn = target(
  #   source_python(file_in("02scripts/Python/SetupCoverScript.py"),convert = FALSE),
  #   trigger = trigger(condition =  length(dir("03processed-data/apsimxFilesLayers/", pattern = "*.db-wal")) != 0,
  #                     mode = "blacklist")
  # ),
  # l_stats_layerKL = autoapsimx::sims_stats_multi(path_sims = path_sims2,
  #                                                pattern = "^LayerKL.+.db$",
  #                                                DT_observation = readd(SW_mean),
  #                                                mode = "Manual",
  #                                                keys = c("Experiment", "SowingDate", "Depth")),
  # DT_stats_layerKL = data.table::rbindlist(l_stats_layerKL, use.names = T, idcol = "Source"),
  # best_fit_layers =  subset_stats(DT_stats_layerKL),
  # Treatments = unique(best_fit_layers[,.(Experiment, SowingDate)]),
  # pred_obs_layerkl = target(
  #   best_fit_layers[Experiment == sites & SowingDate == sds],
  #   transform = cross(sites = c("AshleyDene", "Iversen12"),
  #                     sds = c("SD1",  "SD2", "SD3",  "SD4",  "SD5",
  #                             "SD6",  "SD7",  "SD8",  "SD9",  "SD10"))
  # ), 
  # plot_layerkl_distribution = target(
  #   plot_params(DT = pred_obs_layerkl,
  #               col_pred = "pred_VWC", col_obs = "ob_VWC",
  #               Depth = "Layerkl_distribution",
  #               height = 16, width = 9,
  #               title = file_out(!!paste0(path_layerkl,"/",.id_chr)),format = "png"),
  #   transform = map(pred_obs_layerkl),
  #   trigger = trigger(condition = TRUE, mode = "blacklist")
  #   ),
  # plot_layerkl = target(
  #   plot_params(DT = pred_obs_layerkl,
  #               col_pred = "pred_VWC", col_obs = "ob_VWC",
  #               Depth = "Layerkl",
  #               height = 16, width = 9,
  #               title = file_out(!!paste0(path_layerkl,"/",.id_chr)),format = "png"),
  #   transform = map(pred_obs_layerkl),
  #   trigger = trigger(condition = TRUE, mode = "blacklist")
  # ),
  # # Output the best fit layer kls
  # best_fit_layerkl = target(
  #   process_bestfit(readd(best_fit),  readd(best_fit_layers))
  # ),
  # write_bestfit = target(
  #   data.table::fwrite(best_fit_layerkl, file_out(!!paste0("03processed-data/best_fit_layerkls", ".csv")))
  # )

)
