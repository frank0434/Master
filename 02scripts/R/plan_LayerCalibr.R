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
  
  # files = sapply(seq(1, nrow(info)), function(x){
  #   orig = here::here("03processed-data/apsimxFiles/")
  #   copyto = here::here("03processed-data/apsimxFilesLayers/")
  #   basename = paste0("ModifiedSKL_", 
  #                     info[x, ][["SKL"]],
  #                     info[x, ][["Experiment"]], 
  #                     info[x, ][["SowingDate"]], ".apsimx")
  #   file = file.path(orig, basename)
  #   system(paste("cp", file, copyto))
  # })

  ## Prepare the configuration file and create multiple slurp simulations 
  # .2_Data_EDA_Part2_apsimxEdit.Rmd
  # Set up initial condtions 
  apsimxs = target(
    EditApsimxLayers(apsimx, info, readd(SW_DUL_LL), readd(SD_tidied), kls),
    trigger = trigger(condition =  FALSE)
  ),

  files = list.files(here::here("03processed-data/apsimxFilesLayers/"), 
                     pattern = "^Layer.+.apsimx$", full.names = TRUE),
  # Edit layer from 2 and below
  apsimxlayerkl = target(
    EditLayerKL_multi(KL_layers , KL_range, path =  apsimx,
                      files = files[1:18],
                      saveTo = path_sims2),
    trigger = trigger(condition =  TRUE)
  )
  # l_stats_layerKL = autoapsimx::sims_stats_multi(path_sims = "./03processed-data/apsimxFilesLayers/",
  #                                                pattern = "^SKL.+.db$", 
  #                                                DT_observation = readd(SW_mean),
  #                                                mode = "Manual",
  #                                                keys = c("Experiment", "SowingDate", "Depth")),
  # DT_stats_layerKL = data.table::rbindlist(l_stats_layerKL)
)
