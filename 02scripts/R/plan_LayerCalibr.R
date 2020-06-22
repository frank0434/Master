# plan.R
plan_LayerCalibr <- drake::drake_plan(
  # Data input
  best_fit = readd(top5)[, list(data = list(.SD)), 
                         by = .(Experiment, SowingDate, SimulationID, SKL,KLR, RFV, NSE, R2, RMSE)
                         ][order(NSE, R2,RMSE)
                           ][, .SD[1], by = .(Experiment, SowingDate)],
  info = best_fit[,.(Experiment, SowingDate, SimulationID, SKL, KLR,RFV)],
  # SW_DUL_LL = readd(SW_DUL_LL),
  # SD_tidied = readd(SD_tidied),
  files = sapply(seq(1, nrow(info)), function(x){
    orig = here::here("03processed-data/apsimxFiles/")
    copyto = here::here("03processed-data/apsimxFilesLayers/")
    basename = paste0("ModifiedSKL_", 
                      info[x, ][["SKL"]],
                      info[x, ][["Experiment"]], 
                      info[x, ][["SowingDate"]], ".apsimx")
    file = file.path(orig, basename)
    system(paste("cp", file, copyto))
  })

  ## Prepare the configuration file and create multiple slurp simulations 
  # .2_Data_EDA_Part2_apsimxEdit.Rmd
  # Set up initial condtions 
  # apsimxs = target(
  #   EditApsimxLayers(apsimx, best_fit, SW_DUL_LL, SD_tidied),
  #   trigger = trigger(condition =  FALSE)
  # ),

  # files = list.files("./03processed-data/apsimxFilesLayers/", "^Modif.+.apsimx$", full.names = TRUE),
  # Edit layer from 2 and below
  # apsimxlayerkl = target(
  #   EditLayerKL_multi(layer = layer, KL_range, path =  apsimx, 
  #                     files = files[1:18],
  #                     saveTo = path_sims2),
  #   trigger = trigger(condition =  FALSE)
  # )
  # l_stats_layerKL = autoapsimx::sims_stats_multi(path_sims = "./03processed-data/apsimxFilesLayers/",
  #                                                pattern = "^SKL.+.db$", 
  #                                                DT_observation = readd(SW_mean),
  #                                                mode = "Manual",
  #                                                keys = c("Experiment", "SowingDate", "Depth")),
  # DT_stats_layerKL = data.table::rbindlist(l_stats_layerKL)
)
