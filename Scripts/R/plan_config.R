# plan.R
plan_config <- drake::drake_plan(
  # Data input
  water = read_Sims(path_richard),
  LAI_Height = read_Sims(path = path_richard, 
                      source = "biomass"
                      )[Seed== 'CS' & Harvest.No.!= "Post"
                        ][,..biomass_cols
                          ][, unlist(list(lapply(.SD, mean, na.rm = TRUE)),
                                     recursive = FALSE),
                            by = .(Experiment, SowingDate, Clock.Today),
                            .SDcols = c("Height", "LAImod")],
  sowingDates = read_Sims(path_richard, source =  "sowingDate"), 
  value_vars = grep("SW\\(\\d.+", colnames(water), value = TRUE),
  
  climate_units = read_met_col(here::here("Data/ClimateAndObserved/lincoln.met"), skip = 6),
  
  met_Iversen12 = read_met(here::here("Data/ClimateAndObserved/lincoln.met"), 
                           skip_unit =  7, skip_meta = 6
                           )[, Clock.Today := as.Date(day, origin = paste0(year, "-01-01"))
                             ][Clock.Today > "2010-10-01" & Clock.Today < "2012-08-01"
                               ][, AccumTT := cumsum(mean)
                                 ][, Experiment := "Iversen12"],
  
  met_AshleyDene = read_met(here::here("Data/ClimateAndObserved/AshleyDene.met"), 
                            skip_unit = 10, skip_meta = 8
                            )[, Clock.Today := as.Date(day, origin = paste0(year, "-01-01"))
                              ][Clock.Today > "2010-10-01" & Clock.Today < "2012-08-01"
                                ][, AccumTT := cumsum(mean)
                                  ][, Experiment:="AshleyDene"],
  
  
  # Transformation
  # SWC_mean = water[,lapply(.SD, mean, na.rm = TRUE), 
  #                  by = id_vars, 
  #                  .SDcols = "SWC"],
  accumTT = rbindlist(list(met_Iversen12, met_AshleyDene),
                       use.names = TRUE)[,.(Experiment, Clock.Today, AccumTT)],
  CoverData = trans_biomass(biomass = LAI_Height, 
                            sowingDates, accumTT),
  outputCover = target(
    outputCoverData(CoverData = CoverData, 
                    biomass = LAI_Height, 
                    output = file_out(!!path_cover)),
    trigger = trigger(condition =  length(dir(path_cover)) == 0,
                      mode = "condition")
    ),
  # mean divided by 100 to have vwc
  SW_mean = water[, lapply(.SD, function(x) mean(x, na.rm = TRUE)/100), 
                           by = id_vars,
                           .SDcols = value_vars],

  # Joinning for initial soil water conditions 
  # SW_initials = initialSWC(SW_mean, sowingDates, id_vars),
  
  # DUL AND LL 
  DUL_LL = doDUL_LL(SW_mean, value_vars),

  # Joinning all 
  # SW_DUL_LL = SW_initials[DUL_LL, 
  #                         on = c("Experiment", "SowingDate", "Depth")
  #                         ][,':='(Depth = as.integer(gsub("\\D", "", Depth)))
  #                           ][order(Experiment,SowingDate, Depth, Clock.Today)],
  # 
  # kl ----------------------------------------------------------------------
  ## Prepare the slurp model input 

  ## Prepare the configuration file and create multiple slurp simulations 
  # .2_Data_EDA_Part2_apsimxEdit.Rmd
  # apsimxs = target(
  #   EditApsimx(SW_DUL_LL, sowingDates, file_in(!!path_cover)),
  #   trigger = trigger(condition =  length(dir("Data/ProcessedData/apsimxFiles/")) == 0,
  #                     mode = "condition"))
  # 
)

