# plan.R
plan_LayerCalibr <- drake::drake_plan(
  # Data input - best combination of parameters for the first layer
  best_fit = fread(here::here("03processed-data/20200821bestcomb.csv")),

  info = best_fit[, .SD[1], by = .(Experiment, SowingDate)
                  ][,.(Experiment, SimulationID, SowingDate, SKL, KLR,RFV)],

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

  # Execute apsimx
  simulations = system(paste(apsimx, 
                             "C:/Data/Master/03processed-data/bestfitLayerkl/*.apsimx"))
  # Edit layer from 2 and below
  

)
