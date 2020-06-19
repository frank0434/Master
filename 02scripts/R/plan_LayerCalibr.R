# plan.R
plan_LayerCalibr <- drake::drake_plan(
  # Data input
  best_fit = data.table::fread("./03processed-data/best_fitForSWC_Profile.csv"),
  SW_DUL_LL = readd(SW_DUL_LL),
  SD_tidied = readd(SD_tidied),

  ## Prepare the configuration file and create multiple slurp simulations 
  # .2_Data_EDA_Part2_apsimxEdit.Rmd
  apsimxs = target(
    EditApsimxLayers(apsimx, best_fit, SW_DUL_LL, SD_tidied),
    trigger = trigger(condition =  length(dir("./03processed-data/apsimxFilesLayers/")) == 0,
                      mode = "blacklist")
  )
)
