# plan.R
plan_LayerCalibr <- drake::drake_plan(
  # Data input
  best_fit = data.table::fread("./03processed-data/best_fitForSWC_Profile.csv"),
  SW_DUL_LL = readd(SW_DUL_LL),
  SD_tidied = readd(SD_tidied),

  ## Prepare the configuration file and create multiple slurp simulations 
  # .2_Data_EDA_Part2_apsimxEdit.Rmd
  # Set up initial condtions 
  apsimxs = target(
    EditApsimxLayers(apsimx, best_fit, SW_DUL_LL, SD_tidied),
    trigger = trigger(condition =  FALSE)
  ),

  files = list.files("./03processed-data/apsimxFilesLayers/", "^Modif.+.apsimx$", full.names = TRUE),
  # Edit layer from 2 and below
  # apsimxlayerkl = target(
  #   EditLayerKL_multi(layer = layer, KL_range, path =  apsimx, 
  #                     files = files[1:18],
  #                     saveTo = path_sims2),
  #   trigger = trigger(condition =  FALSE)
  # )
  l_stats_layerKL = autoapsimx::sims_stats_multi(path_sims = "./03processed-data/apsimxFilesLayers/",
                                                 pattern = "^SKL.+.db$", 
                                                 DT_observation = readd(SW_mean),
                                                 mode = "Manual",
                                                 keys = c("Experiment", "SowingDate", "Depth")),
  DT_stats_layerKL = data.table::rbindlist(l_stats_layerKL)
)
