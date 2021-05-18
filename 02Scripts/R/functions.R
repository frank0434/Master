

prepare_params <- function(params){
  params <- params[!is.na(parameter)
                   ][,.(parameter, lower, uppper, layer)
                     ][, initials:= uppper/2]
  return(params)
}

#' wrapper_deoptim
#'
#' @param parameters 
#' @param obspara 
#' @param maxIt 
#' @param np 
#' @param ... , input object will be passed into functions within optimisation
#'
#' @return
#' @export
#'
#' @examples
wrapper_deoptim <- function(parameters, par,  maxIt, np, ...){
  # maxIt <- 10
  # np <- 3
  # Capture the ellipsis 
  l <- list(...)
  # Examine the list 
  # print(l)
  # Get the name of the input objects
  arg_input <- as.character(as.list(substitute(list(...))))[-1]
  # Examine the names
  # print(arg_input)
  # Remove the site and SD for input_list
  obj_nms <- gsub("_(Ash|Ive).+_SD\\d{1,}$","", arg_input, ignore.case = TRUE)
  # print(obj_nms)

  # import necessary input from cache
  for (i in seq_len(length(l))) {
    assign(obj_nms[i], l[[i]],
           envir = .GlobalEnv
           )
  }
  # print(ls(envir = .GlobalEnv))
  # print(parameters)
  # print(par)
  
  # import necessary functions 
  # source(here::here("02Scripts/R/functions.R"))
  low <- parameters$lower
  up <- parameters$uppper
  # The observaion value that will be used as the benchmark
  # obspara <- "SWCmm"
  
  opt.res <- DEoptim::DEoptim(fn=cost.function,
                              lower = low,
                              upper = up,
                              control=list(NP=np * 1, itermax=maxIt, parallelType=1,
                                           storepopfrom = 1, trace = 1,
                                           packages = c('RSQLite','here'),
                                           parVar = c("APSIMEditFun",
                                                      "APSIMRun",
                                                      # "obspara",
                                                      obj_nms))
  )
  return(opt.res)
  
  

  
}
  # save(opt.res, file =  file.path(apsimx_sims_dir,
  #                                 paste0(Sys.Date(), 'opt.res', ".RData")))
  # 
  # fit.par = data.frame(estimates = opt.res$optim$bestmem, 
  #                      cost = opt.res$optim$bestval)
  # 
  # 
  # #output the statistical test
  # par = fit.par$estimates
  # 
  # write.csv(par, here::here("01Data/ProcessedData/opt.par.csv"), row.names = F)
#' Title
#'
#' @param par 
#' @param obspara 
#' @param reset 
#'
#' @return
#' @export
#'
#' @examples
cost.function <- function(par, obspara = "SWCmm", reset = magicDate){
  
  id <- paste0(round(par, digits = 3), collapse = '_')
  cat("Processing param combination: ",par, "\r\n")
  APSIMEditFun(par)
  APSIMRun(par)
  db <- RSQLite::dbConnect(RSQLite::SQLite(),
                           paste0(apsimx_sims_dir, '/temp', Sites, "_", SD, "_", id,'.db'))
  
  
  PredictedObserved <- data.table::as.data.table(
    RSQLite::dbReadTable(db,"PredictedObserved"))
  PredictedObserved <- PredictedObserved[Clock.Today >= reset]
  # Generate multiple cost depends on user input of observation variables 
  no.ofobspara <- length(obspara)
  l <- vector("list", length = no.ofobspara)
  names(l) <- obspara
  for (i in seq_len(no.ofobspara)){
    pre_col <- paste0("Predicted.", obspara[i])
    obs_col <- paste0("Observed.", obspara[i])
    l[[i]] <- sum(na.omit(PredictedObserved[[pre_col]]- 
                            PredictedObserved[[obs_col]])^2)
  }
  
  totalCost = 0 
  totalCost = sum(unlist(l))
  
  RSQLite::dbDisconnect(db)
  
  rm(db)
  gc()
  
  system(paste("rm", paste0(apsimx_sims_dir, "/temp", Sites, "_", SD, "_", id, "*")))
  
  return(totalCost)
}

#' Title
#'
#' @param par 
#'
#' @return
#' @export
#'
#' @examples
APSIMRun <- function(par){
  # Create a new name for the apsimx file 
  id <- paste0(round(par, digits = 3), collapse = '_')
  path_config <- here::here("01Data/ProcessedData/ConfigurationFiles", 
                            paste0("temp", Sites,"_", SD,"_", id, ".txt"))
  # Create a new name for the apsimx file 
  newname <- paste0(apsimx_sims_dir, '/temp', Sites,"_", SD, "_", id, ".apsimx")
  
  # Copy base apsimx file to its new name 
  print(path_apsimx)
  print(newname)
  file.copy(apsimx_Basefile, newname)
  # Modify the apsimx file 
  system(paste(path_apsimx, "--edit", path_config, newname))
  
  # # Execute the new apsimx file 
  # system(paste(apsimx, newname, 
  #                "/NumberOfProcessors:8"))
  
}



#' APSIMEditFun
#'
#' @param par 
#' @param nodes 
#' @param initial_cond 
#' @param input_list 
#'
#' @seealso \code{\link{APSIMRun}}
#' @return
#' @export
#'
#' @examples
APSIMEditFun <- function( par, nodes = template,
                          initial_cond = 16L,
                          input_list. = input_list){
  no.ofPara <- length(par)
  id <- paste0(round(par, digits = 3), collapse = '_')
  
  temp_initial <- gsub("(?<=\\=)\\s.+$","",nodes, perl = TRUE)
  temp_ini_list <- vector("list", length = length(temp_initial))
  names(temp_ini_list) <- temp_initial
  ## initial configuration
  temp_ini_list$`[Site].Name =` <- input_list.[[1]]
  temp_ini_list$`[DataStore].ExcelInput.FileNames = ` <- input_list.[[2]]
  temp_ini_list$`[SlurpSowingRule].Script.SowingDate =` <- as.character(input_list.[[3]]$Clock.Today)
  temp_ini_list$`[Weather].FileName =` <- input_list.[[4]]
  temp_ini_list$`[SetCropVariables].Script.CoverFile =` <-  input_list.[[5]]
  temp_ini_list$`[SetCropVariables].Script.MaximumHeight =` <-  input_list.[[6]]
  temp_ini_list$`[Soil].Physical.BD =` <- paste( input_list.[[7]]$BD_kg.m3/1000, collapse = ",")
  temp_ini_list$`[Soil].InitialConditions.SW =` <- paste( input_list.[[8]]$SW,
                                                          collapse = ",")
  temp_ini_list$`[Soil].Physical.DUL =` <- paste( input_list.[[9]]$SW.DUL,
                                                  collapse = ",")
  temp_ini_list$`[Soil].Physical.SlurpSoil.LL =`<- paste(input_list.[[9]]$SW.LL,
                                                         collapse = ",")
  temp_ini_list$`[Soil].Physical.SAT =`<- paste(input_list.[[9]]$SAT,
                                                collapse = ",")
  temp_ini_list$`[Soil].Physical.AirDry =`<- paste(input_list.[[9]]$SW.LL,
                                                   collapse = ",")
  temp_ini_list$`[Soil].Physical.LL15 =`<- paste(input_list.[[9]]$SW.LL,
                                                 collapse = ",")
  temp_ini_list$`[ResetOnDate].Script.ResetDate =` <- paste(input_list.[[10]]$Clock.Today,
                                                 collapse = ",")
  temp_ini_list$`[ResetOnDate].Script.ResetWater =`<- "Yes"
  temp_ini_list$`[ResetOnDate].Script.NewSW =`<- paste(input_list.[[11]]$SW,
                                                       collapse = ",")
  for(i in (initial_cond+1):length(nodes)){
    temp_ini_list[[i]] <- par[i-initial_cond]
  }
  path_config <- here::here("01Data/ProcessedData/ConfigurationFiles", 
                      paste0("temp", Sites, "_", SD, "_", id, ".txt"))
  f<- file(path_config, "w")
  
  for(i in seq_len(length(nodes))){
    line <- paste0(names(temp_ini_list[i]) ," ", temp_ini_list[[i]])
    cat(line, "\r",
        file = f, 
        append = TRUE)
  }
  # Close the file and clean it from memory 
  close(f)
  rm(f)
  gc()
}
#' combine_input
#' @description pack a number of objects into a list and name with their object
#' names 
#'
#' @param ... 
#'
#' @return
#' @export
#'
#' @examples
combine_input <- function(...){

  nms <- as.character(as.list(substitute(list(...))))[-1]
  l <- list(...)
  names(l) <- nms
  l
}


#' prepare_obs
#'
#' @param DT 
#' @param trts 
#'
#' @description Read raw observation data and prepare it into apsimx readable
#' excel format. currently, works only for richard's raw data
#'
#' @return
#' @export
#'
#' @examples
prepare_obs <- function(DT, trts = c("AshleyDene", "SD1")){
  # Define variables for output
  idvars <- c("Data","Site", "Date", "Season", "Sowing.Date", 
              # "Rep", "Plot",  
              "Seed", "Rotation.No.", "Harvest.No.",  "DAS")
  valvars <- c("Height", "Shoots.m2", "Total.DM", "Leaf.DM", "Stem.DM","SLA..FW.",
               "SLA..DW.", "LAImod", "Root.Total", "Crown", 
               paste0("SWC.0.", 1:23), "SWC.2.3.m..mm.",
               "MS.node.No", "Growth.stage")
  # Subset and manipulation 
  cols <- c(idvars, valvars)
  richard_long <- DT[Data %in% c("Biomass", "Root",
                                 "Phenology", "Soil water") &
                       Seed == "CS",
                     ..cols
                     ][, SWC.0.1:= SWC.0.1+SWC.0.2
                       ][, SWC.0.2 := NULL] %>% 
    setnames(., paste0("SWC.0.", c(1,3:23)), paste0("SWmm(", 1:22,")")) %>% 
    melt.data.table(id.vars = idvars, na.rm = TRUE)
  # Aggregate into means 
  groupkey <- c(idvars, "variable")
  agg <- richard_long[, unlist(lapply(.SD, function(x) 
    list(mean=mean(x, na.rm = TRUE),
         sd = sd(x, na.rm = TRUE),
         n = .N,
         Upper = max(x, na.rm = TRUE),
         Lower = min(x, na.rm = TRUE))
  ), recursive = FALSE), by = groupkey]
  # Transform it into wide format 
  keycols <- c(idvars, "variable", "value.mean")
  
  mean_se <- agg[, se := value.sd/sqrt(value.n)
  ][!(Data == "Phenology" & variable == "LAImod")]
  obs_Richard <- mean_se[,..keycols] %>% 
    dcast.data.table(Data + Site + Sowing.Date + Season + Date + 
                       DAS + Rotation.No.+ Harvest.No.~ variable,
                     value.var = c("value.mean"))
  # Manually tidy up column names 
  setnames(obs_Richard, 
           c("Sowing.Date", "Date","Shoots.m2", "Total.DM", "Leaf.DM","Stem.DM",
             "LAImod", 
             "Root.Total", "SWC.2.3.m..mm.",
             "Growth.stage"),
           c("SowingDate", "Clock.Today","ShootPopulation", "ShootWt", "LeafWt",
             "StemWt", "LAI", "RootWt", "SWCmm", "GrowthStage"))
  outpath <- here::here("01Data/ProcessedData/CoverData",
                       paste0(paste(trts, collapse = "_"),".xlsx"))
  DT <- obs_Richard[Site == trts[1]&
                SowingDate == trts[2]
              ][, SimulationName := paste0(Site, "SowingDate", SowingDate)
                ][, (c("Site", "SowingDate","Data","Season","DAS",
                       "Rotation.No.","Harvest.No.")) := NULL]
  write.xlsx(x = DT[, Clock.Today := as.Date(Clock.Today)], 
             file = outpath, 
             sheetName = "ObsAllData")
  return(outpath)
  
  
}


subset_met <- function(met){
  DT <- met[,.(Experiment, Clock.Today, AccumTT)]
  return(DT)
}

#' filter_SD 
#' @description Helper function to get the pipeline dependencies right.
#'
#' @param DT 
#' @param trts 
#'
#' @return
#' @export
#'
#' @examples
filter_SD <- function(DT, trts){
  SD <- DT[Experiment == trts[1] &
             SowingDate == trts[2]]
  SD
}

#' Title
#'
#' @param DT 
#' @param date 
#' @param trts order of trts matters, first is the site
#'
#' @return
#' @export
#'
#' @examples
filter_SW <- function(DT,  trts){
  DT <- DT[Experiment == trts[1] &
             SowingDate == trts[2]]
  DT
  
  }

#' filter_BD
#'
#' @param path 
#' @param Sites 
#'
#' @return
#' @export
#'
#' @examples
filter_BD <- function(path, Sites){
  BD <- data.table::as.data.table(
    readxl::read_excel(path)
  )
  BD <- BD[Experiment == Sites]
  
  
  }

#' Title
#'
#' @param dt 
#' @param col_obs 
#' @param col_pre 
#' @param color 
#' @param scale 
#'
#' @return
#' @export
#'
#' @examples
plot_PreObs <- function(dt, col_obs, col_pre, 
                        color = "SowingDate", scale = "fixed"){
  base_p <- dt %>% 
    ggplot(aes(x = .data[[col_obs]],
               y = .data[[col_pre]]
               # shape = SowingDate,
               # colour = .data[[color]]
    )) +
    geom_point(size = 3, alpha = 0.8) +
    facet_wrap( ~ Experiment, scales = scale)
  return(base_p)
}


#' Title
#'
#' @param DT 
#' @param key 
#' @param pre_col 
#' @param obs_col 
#'
#' @return
#' @export
#'
#' @examples
key_stats <- function(DT, key =c("Experiment"), pre_col, obs_col){
  stats <-  sims_stats(DT, keys = key,
                       col_pred = pre_col,
                       col_obs = obs_col)
  stats_rs <- stats[, unlist(stats, recursive = FALSE), by = .(Experiment)]
  stats_rs[, ':='(R2_str = paste0(as.character(expression(italic(R)^2 ~"=")), "~",R2),
                  NSE_str = paste0(as.character(expression(NSE~"=")), "~", NSE),
                  RMSE_str = paste0(as.character(expression(RMSE~" = ")), "~", RMSE),
                  nRMSE_str = paste0(as.character(expression(nRMSE~" = ")), "~", `NRMSE %`/100))]
  return(stats_rs)
}
#' norm_stats
#'
#' @description this function is designed to be used with data.table and lappy
#' 
#' @param x a numeric vector 
#'
#' @return
#' @export
#'
#' @examples
norm_stats <- function(x){
  l <- list(mean=mean(x, na.rm = TRUE),
            sd = sd(x, na.rm = TRUE),       
            n = .N,
            Upper = max(x, na.rm = TRUE),
            Lower = min(x, na.rm = TRUE))
  return(l)
  } 
#### Graph function

#' plot_timecourse
#' @description This function is tailored to plot a time course faceted plot 
#' for apsimx simulation and observation comparision
#' 
#' @param DT a data.table. This table is the predict and observe table in apsimx
#' db
#' @param var a character string for variable name
#' @param unit a character vector for the unit if any or anything that is 
#' associated with the variable. create an empty one "" if nothing 
#' @param label a character string to show the label for the variable 
#'
#' @return
#' @export
#'
#' @examples
plot_timecourse <- function(DT, var, unit, label){
  pre_col <- paste0("Predicted.", var, unit)
  obs_col <- paste0("Observed.", var, unit)
  pre_color <- "black"
  obs_color <- "#FF0000"
  pre_label <- paste("Predicted", var, label)
  obs_label <- paste("Observed", var, label)
  
  var_subset <- c("Experiment","SowingDate", "Clock.Today",
                  pre_col, obs_col)
  DT_sub <- unique(DT[Clock.Today >= magicDate, 
                      ..var_subset])
  DT_sub <- fix_SDorder(DT_sub)
  # label and colour
  timestep_colors <- c(pre_color,obs_color)
  names(timestep_colors) <- c(pre_col, obs_col)
  timestep_labels <- c(pre_label, obs_label)
  names(timestep_labels) <- c(pre_col, obs_col)
  # Graphing
  timestep_p <- DT_sub %>% 
    ggplot(.,aes(Clock.Today )) +
    geom_point(aes(y = .data[[obs_col]], color = {{obs_col}}),
               size = 3)+
    geom_line(aes(y = .data[[pre_col]], color = {{pre_col}}), 
              show.legend = TRUE,size = 1) +
    facet_wrap( ~  SowingDate + Experiment,
                strip.position = "right", nrow = 10, scales = "free_y") +
    theme_water()  +
    theme(legend.position = "none", legend.key.size = unit(1, "cm")) +
    labs(y = paste(gsub("Predicted\\.|mm", "", pre_col), label), 
         x = "Date") +
    scale_colour_manual(name = "col", values = timestep_colors, labels = timestep_labels)
  timestep_p
}


#' morrisEE
#' @description Calculate elementary effect for all input parameter to one output.
#' Copied the method from the apsimx buildin Morris method (OAT). 
#' 
#' @param Output a data.table
#' @param variable string. variable name for the output column
#' @param apsimMorris pre-defined morris sampling model
#' @param path integer. how many iterations, same as the one in morris model definition.
#' @param parameters charater strings. the parameter names used in morris model.
#'
#' @return a list has two data.frame. one for path analysis one for statistics. 
#' @export
#'
#' @examples
morrisEE <- function(Output, variable = "SW1", apsimMorris, 
                     path = paths, parameters = params){
  
  allEE <- data.frame()
  allStats <- data.frame()
  apsimMorris$y <-  Output[[variable]]
  
  tell(apsimMorris)
  ee <- data.frame(apsimMorris$ee)
  ee$variable <-variable
  ee$path <- seq_len(path)
  allEE <- rbind(allEE, ee)
  mu <- apply(apsimMorris$ee, 2, mean)
  mustar <- apply(apsimMorris$ee, 2, function(x) mean(abs(x)))
  sigma <- apply(apsimMorris$ee, 2, sd)
  stats <- data.frame(mu, mustar, sigma)
  stats$param <- parameters
  stats$variable <- variable
  allStats <- rbind(allStats, stats)
  l <- list(allStats, allEE)
  names(l) <- c("stats", "pathanalysis")
  return(l)
  
}


# critical functions  -----------------------------------------------------

#' relativeSW
#' @description calculate the relative soil water content for each observation
#' baseline is the maximum soil water content value
#'
#' @param DT a data table has mean value for each measurement 
#' @param col_pattern a character string to help extract all columns
#' @param id_vars a character string to define the id columns
#'
#' @return data.table
#' @import data.table
#'  
#' @export
#'
#' @examples
#' 
relativeSW <- function(DT, col_pattern = "VWC", id_vars){
  VWC <- grep(pattern = col_pattern, x = colnames(DT), value = TRUE)
  VWCcols <- c(id_vars, VWC)
  DT_VWC <- DT[,..VWCcols] %>% 
    melt.data.table(id.vars = id_vars, 
                    value.name = "SW",
                    variable.name = "Depth",
                    variable.factor = FALSE)
  DT_VWC[, Depth:= as.integer(gsub("\\D","",Depth))]
  DT_VWC[, DUL := max(SW), by = .(Experiment, SowingDate, Depth)
         ][, relativeSW:= SW/DUL]
  return(DT_VWC)
  
}

#' window_DT
#' @description A subset function for data.table object. similar to `window` 
#' function for `ts`object. 
#'
#' @param DT 
#' @param startd 
#' @param endd 
#'
#' @import data.table
#' @return
#' @export
#'
#' @examples
window_DT <- function(DT, Site, startd = "2011-04-01", endd = "2012-04-30"){
  DT <- DT[ Experiment == Site & Clock.Today %between% c(startd, endd)]
  return(DT)
}
#' estimate_DUL
#' @description use the change point analysis to estimate the DUL from their
#' relative soil water content in each layer
#'
#' @param DT 
#' @param sowingdate 
#' @param layer 
#' @param mcpmodel 
#'
#' @return
#' @export
#'
#' @examples
estimate_DUL <- function(DT, mcpmodel = model, priorinfo = prior){
  # Fit it. 
  fit = mcp(mcpmodel, data = DT, cores = 3, prior = priorinfo)
  # Extract the cp one 
  cp_1_est = as.data.table(fixef(fit))
  setkey(DT, DAS)
  close_das = DT[DT[J(cp_1_est$mean[1]), roll = 'nearest', which = TRUE]
  ]
  l <- list(fit,cp_1_est, close_das)
  names(l) <- c("model","cp1", "nearDAS")
  return(l)
}

#' Title
#'
#' @param DT 
#'
#' @return
#' @export
#'
#' @examples
process_esti <- function(DT, model = mcpmodel, priorinfo = prior){
  DT <- DT[, esti := list(apply(.SD, 1, function(x){
    l <- estimate_DUL(x[["data"]], mcpmodel = model, priorinfo = priorinfo)
    return(l)
    })), by = .(Experiment)
    ][, results:= lapply(esti, function(x){
      cp1_int1 <- x$cp1$mean[4]
      dt = x$nearDAS[, esti_DUL := cp1_int1
                     ][, SW.DUL := esti_DUL * DUL]
      return(dt)
      })]
  return(DT)
}


##' .. content for \description{column wise mean calculation, mm SW will be
##' converted to VWC} 
##'
##' .. content for \details{} ..
##'
##' @title colwise_meanSW
##'
##' @param id.vars 
##' @param col.vars 
##' @param data_SW
##' @import data.table
##'
##' @return
##' @author frank0434
##' @export
colwise_meanSW <- function(DT, id.vars = id_vars, col.vars = value_vars){
  
  mean_SW <- DT[, unlist(lapply(.SD, function(x) list(mean=mean(x, na.rm = TRUE),
                                                          sd = sd(x, na.rm = TRUE),
                                                          n = .N,
                                                          Upper = max(x, na.rm = TRUE),
                                                          Lower = min(x, na.rm = TRUE))),
                             recursive = FALSE), 
                    by = id.vars,
                    .SDcols = col.vars]
  meancols <- grep("mean", colnames(mean_SW), value = TRUE)
  mean_SW[, ':='(SW.1..VWC= round(SWmm.1..mean/200, digits = 3))
            ][, (paste0("SW.",2:22, "..VWC")) := lapply(.SD, function(x) round(x/100, digits = 3)),
              .SDcols = meancols[-1]][]
  mean_SW


}


#' filter_datemax
#' @description need to know which date has the maximum and minimum SW to figure
#'   out the range from the replicates
#'
#' @param mean_SW 
#'
#' @return
#' @export
#'
#' @examples
filter_datemax <- function(mean_SW, mode = c("max", "min"), id.vars = id_vars){
  if(mode == "max"){
    TEST <- data.table::melt.data.table(mean_SW, id.vars = id.vars, 
                                        variable.name = "Depth", 
                                        variable.factor = FALSE,
                                        value.name = "SW") %>% 
      dplyr::group_by(Experiment, SowingDate, Depth) %>% 
      dplyr::filter(SW == max(SW)) %>% 
      dplyr::group_by(Experiment, SowingDate, Depth, SW) %>% 
      dplyr::filter(Clock.Today == first(Clock.Today))
  } else if(mode == "min"){
    TEST <- data.table::melt.data.table(mean_SW, id.vars = id.vars, 
                                        variable.name = "Depth", 
                                        variable.factor = FALSE,
                                        value.name = "SW") %>% 
      dplyr::group_by(Experiment, SowingDate, Depth) %>% 
      dplyr::filter(SW == min(SW)) %>% 
      dplyr::group_by(Experiment, SowingDate, Depth,SW) %>% 
      dplyr::filter(Clock.Today == first(Clock.Today))
  }

  
  return(TEST)
}

##' .. content for \description{} 
##'
##' .. content for \details{} ..
##'
##' @param SW 
##' @param id.vars 
##' @param value.vars 
##' @param startd 
##' @param endd 
##'
##' @title doDUL_LL_range
##' @return
##' @author frank0434
##' @export
doDUL_LL_range <- function(SW, id.vars = id_vars,  
                           startd = "2011-01-01", endd = "2012-06-30") {

  SW <- SW[Clock.Today %between% c(as.Date(startd), as.Date(endd))]
  # should only choose first 5 sowing dates for this
  needed <- grep("VWC", colnames(SW), value = TRUE)
  needed <- c(id.vars, needed)
  VWC <- SW[,..needed]

  Dates_max <- filter_datemax(mean_SW = VWC, id.vars = id.vars, mode = "max")
  Dates_min <- filter_datemax(mean_SW = VWC, id.vars = id.vars, mode = "min")

  DT <- data.table::melt.data.table(VWC, id.vars = id.vars, 
                                    # measure.vars = value.vars,
                                    variable.name = "Depth",
                                    variable.factor = FALSE,
                                    value.name = "SW")
  
  DUL_range <- DT[setDT(Dates_max), on = c("Experiment", "SowingDate", "Depth", 
                                             "Clock.Today")]
  LL_range <- DT[setDT(Dates_min), on = c("Experiment", "SowingDate", "Depth", 
                                            "Clock.Today")]
  ranges <- merge.data.table(DUL_range, LL_range, 
                             by = c("Experiment", "SowingDate", "Depth"),
                             suffixes = c(".DUL", ".LL"))
  ranges <- ranges[, Depth := as.integer(gsub("\\D", "", Depth))
                   ][order(Experiment, SowingDate, Depth)]
  return(ranges)
  
}




#' template_slurp
#'
#' @param outpath 
#' @param template_var 
#' @param template_value 
#'
#' @return
#' @export
#'
#' @examples
#' 

config_slurp <- function(template_var, template_value, outpath){
  # template = readLines("01Data/ApsimxFiles/SlurpBaseConfigTemplate.txt")
  # loadd(SW_DUL_LL)
  # template_value = c(path_AD, 
  #                    390,
  #                    DB_AshleyDene,
  #                    "2010-10-21",
  #                    paste0("2010-10-21", "T00:00:00"),
  #                    file.path(CoverDataDir,paste0("LAI", i, j, ".csv")),
  #                    replacement_initialSW <- SW_DUL_LL[Experiment == i & SowingDate == j]$SW
  #                    replacement_DUL <- SW_DUL_LL[Experiment == i & SowingDate == j]$DUL
  #                    replacement_SAT <- replacement_DUL
  #                    replacement_AirDry <- replacement_LL
  #                    replacement_LL15 <- replacement_LL
  #                    replacement_LL <- SW_DUL_LL[Experiment == i & SowingDate == j]$LL
  #                    replacement_KL <- skl
  #                    )
  
  
}

##' .. content for \description{} (no empty lines) ..
##'
##' .. content for \details{} ..
##'
##' @title outputobserved

##' @param output 
##'
##' @param biomass 
##' @param site 
##' @param SD 
##' @param SW 
##' 
##' @import openxlsx
##' @return
##' @author frank0434
##' @export
outputobserved <- function(biomass, SW, site, SD,
                              output = "Data/ProcessedData/CoverData/"){
  # OUPUT CONFIG
  
  if(!dir.exists(output)){
    dir.create(output)
  }
 
    # Output observation 
    sitesd  <-  biomass[Experiment == site & SowingDate == SD]
    sitesdSW <- SW[Experiment == site & SowingDate == SD]
    DT <- merge.data.frame(sitesd, sitesdSW,
                           by = c("Experiment","SowingDate",	"Clock.Today"), 
                           all = TRUE)
    # Create a Pandas Excel writer using XlsxWriter as the engine.
    output <- file.path(output, paste0("Observed", site, SD, ".xlsx"))
    openxlsx::write.xlsx(x = DT, file = output, sheetName = "Observed")

  return(output)

  
}

#' outputLAIinput
#'
#' @param CoverData 
#' @param site 
#' @param SD 
#' @param output 
#'
#' @return
#' @export
#'
#' @examples
outputLAIinput <- function(CoverData, site, SD,
                           output = "01Data/ProcessedData/CoverData/"){
  # OUPUT CONFIG
  
  if(!dir.exists(output)){
    dir.create(output)
  }
  
  # Output daily LAI with k
  DT <- CoverData[Experiment == site & SowingDate == SD
                  ][, .(Clock.Today, LAI, k)
                    ][, LAI := ifelse(is.na(LAI) | is.null(LAI), 0, LAI)]
  output <- file.path(output, paste0("LAI_", site, "_", SD, ".csv"))
  data.table::fwrite(x = DT, output)
  
  return(output)
  
  
}





##' .. content for \description{} (no empty lines) ..
##'
##' .. content for \details{} ..
##'
##' @title trans_biomass
##' @description only works for Richard Sim's PhD data 

##' @param biomass 
##'
##' @param sowingDate 
##' @param accumTT 
##' @import zoo
##' @return
##' @author frank0434
##' @export
interp_LAI <- function(biomass = LAI_Height, sowingDate, accumTT, 
                       trts = c("AshleyDene", "SD1")) {

  LAI_Height_SD <- merge.data.table(biomass, sowingDate, 
                                    by = c("Experiment", "Clock.Today" , "SowingDate"),
                                    all = TRUE)[,
                                               ':='(LAImod = ifelse(is.na(LAImod), 0, LAImod),
                                                    Height = ifelse(is.nan(Height), NA, Height))]
  
  LAI_wide <- dcast.data.table(LAI_Height_SD, 
                               Experiment + Clock.Today ~ SowingDate, 
                               value.var = "LAImod" )

  DT <- merge.data.table(accumTT, LAI_wide, by = c("Experiment", "Clock.Today"), 
                         all.x = TRUE)
  
  DT <- melt.data.table(data = DT, 
                        id.vars = c("Experiment", "Clock.Today", "AccumTT"), 
                        value.name = "LAI",
                        variable.name = "SowingDate", variable.factor = FALSE)
  
  DT <- DT[, LAI:= zoo::na.approx(LAI, na.rm = FALSE) , by = .(Experiment, SowingDate) ]
  
  DT <- DT[, ':='(k = 0.94)
     ][Experiment == "AshleyDene" & Clock.Today %between% c( '2011-11-30','2012-03-01'),
       k:= 0.66][, LI := 1 - exp(-k * LAI) ]
  
  outputLAIinput(DT, site = trts[1], SD = trts[2],
                 output = here("01Data/ProcessedData/CoverData/"))
  
}

reset_SD <- function(DT, reset_to = magicDate){
  DT <- copy(DT)[SowingDate%in% paste0("SD", 1:5), 
                 Clock.Today := reset_to]
  return(DT)
  }
##' .. content for \description{} (no empty lines) ..
##'
##' .. content for \details{} ..
##'
##' @initialSWC
##' @description Join aggregated soil water data with sowing dates to get the
##'   initial soil water content

##' @param DT 
##'
##' @param sowingDate 
##' @param id_vars 
##'
##' @import data.table
##' @return
##' @author frank0434
##' @export
initialSWC <- function(DT, sowingDate, id_vars) {
  needed <- grep("SW.\\d.", colnames(DT), value = TRUE)
  needed <- c(id_vars, needed)
  
  if(is.data.table(sowingDate) | is.data.frame(sowingDate)){
    
  SW_initials = DT[,..needed][sowingDate, 
                              on = c("Experiment", "SowingDate", "Clock.Today"),
                              roll = "nearest"]
  } else if(is.character(sowingDate)){
    SW_initials = DT[Clock.Today == sowingDate][,..needed]
  } else{
    print("Please provide valid sowing dates or starting dates.")
  }
  

  SW_initials_melted = data.table::melt.data.table(
    SW_initials, 
    id.vars = id_vars, 
    variable.factor = FALSE,
    variable.name = "Depth",
    value.name = "SW" )
  SW_initials_tidied = SW_initials_melted[, Depth := as.integer(gsub("\\D", "", Depth))
                                          ][order(Experiment, SowingDate, Depth)]
  # SW_initials_tidied = SW_initials_melted[Stats == "mean" & Depth == 1, ':='(SW = round(SW/200, digits = 3))]
  # SW_initials_tidied = SW_initials_tidied[Stats == "mean" & Depth != 1, ':='(SW = round(SW/100, digits = 3))]
  return(SW_initials_tidied)
  
}


# read functions ----------------------------------------------------------



#' read_met
#'
#' @param path A character string. The path to access the met files.
#' @param skip_unit An integer. The number of rows for skipping the unit line in met files.
#' @param skip_meta An integer. The number of rows for skipping the meta data before the column names start.
#' @param startd
#' @param endd
#' @param site
#'
#' @return A data .table and .frame is returned.
#'
#' @import data.table
#' @export
#'
#' @examples
#' \dontrun{
#' read_met("path", skip_unit = 9, skip_meta = 7)
#' }
read_met <- function(path = path_met){
  
  switch <- as.logical(grep("AshleyDene", x = path))
  if(isTRUE(switch)){
   skip_unit = 10
   skip_meta = 8
   site = "AshleyDene"
  } else{
    skip_unit = 8
    skip_meta = 6
    site = "Iversen12"
  }

  startd = "2010-10-01"
  endd = "2012-08-01"
  
  start_date <- as.Date(startd)
  end_date <- as.Date(endd)
  met_LN <- data.table::fread(input = path,skip = skip_unit, fill = TRUE)
  met_col <- read_met_col(path = path, skip = skip_meta)
  colnames(met_LN) <- colnames(met_col)
  
  met_LN <- met_LN[, Clock.Today := as.Date(day, origin = paste0(year, "-01-01"))
  ][Clock.Today > start_date & Clock.Today < end_date
  ][,Date := Clock.Today]
  met_LN <- group_in_season(met_LN)[, AccumTT := cumsum(mean),
                                    by = Season
  ][, Experiment:=site]
  
  return(met_LN)
}


#' read_Sims
#'  @description Read Sims PhD data from excel. It tailors to this excel file. 
#'
#' @param path The path to the excel file.
#' @param source A string vector to declare which data source. Default is
#'   `Soil Water`
#'
#' @return a data.table
#' 
#' @import data.table
#'         readxl
#'         inspectdf
#' 
#' @export
#'
#' @examples
read_Sims <- function(path, source = "Soil Water"){
  dt = readxl::read_excel(path, guess_max = 10300, sheet = 2,
                  .name_repair ="universal",
                  skip = 9 ) # fix the names 
  dt = data.table::as.data.table(dt) 
  data.table::setnames(dt, old = c("Site", "Date", "Sowing.Date"), 
                       new = c("Experiment", "Clock.Today", "SowingDate"))
  dt[, ...119 := NULL]
  col_type =  inspectdf::inspect_types(dt)
  col_date = col_type$col_name[[3]]
  dt[, (col_date) := lapply(.SD, function(x) as.Date(x,  tz = "Pacific/Auckland")),
     .SDcol = col_date]
  
  if(source == "Soil Water"){
    SoilWater = dt[Data == "Soil water"]
    
    col_good = choose_cols(SoilWater) # identify the right cols 
    SoilWater <- SoilWater[,..col_good]
    # Fix the colnames here 
    # Fix the layer 
    
    SoilWater[, Data:=NULL 
              ][, SWC.0.1 := SWC.0.1 + SWC.0.2
                ][, SWC.0.2 := NULL] # Drop the second layer
    # New model separate the top 20 cm 
    # Fix the name to match APSIM soil
    swc_vars = grep("SWC", colnames(SoilWater), value = TRUE)
    data.table::setnames(SoilWater, swc_vars[-length(swc_vars)], paste0("SWmm.", seq(1, 22, 1), "."))
    data.table::setnames(SoilWater, "SWC.2.3.m..mm.", "PSWC")
    return(SoilWater)
  }
  if(source == "sowingDate"){ # need to add a patial match
    sowingDate <- dt[,...120 : I12][!is.na(...120)]
    setnames(sowingDate, "...120", "SowingDate", skip_absent = TRUE)
    SD = sowingDate[, (c("AD", "I12")) := lapply(.SD, as.Date), 
                     .SDcols = c("AD", "I12")] %>% 
      data.table::melt.data.table(id.vars = "SowingDate", 
                       variable.name = "Experiment", value.name = "Clock.Today",
                       variable.factor = FALSE) 
    SD_tidied = SD[, Experiment := ifelse(Experiment == "AD", 
                                          "AshleyDene",  
                                          "Iversen12")]
    return(SD_tidied)
  }
  if(source == "biomass"){
    biomass_cols <- c('Experiment', 'Clock.Today', 'SowingDate', 'Rep',
                      'Plot', 'Rotation.No.', 'Harvest.No.', 'Height','LAImod')
    
    biomass <- dt[Data == "Biomass"]
    
    col_good <- choose_cols(biomass) # identify the right cols 
    
    biomass <- biomass[,..col_good]
    biomass <- biomass[, c("...120", "AD", "I12") := NULL
                       ][Seed== 'CS' & Harvest.No.!= "Post"
                         ][,..biomass_cols
                           ][, unlist(list(lapply(.SD, mean, na.rm = TRUE)),
                                      recursive = FALSE),
                             by = .(Experiment, SowingDate, Clock.Today),
                             .SDcols = c("Height", "LAImod")]
    return(biomass)
    
  }
  }

#' chop_dates
#'
#' @description Chop a date object into year, yearMonth and monthDay
#' 
#' @param DT a data.table
#' @param col_date a string for the date object column
#'
#' @return
#' @export
#'
#' @examples
chop_dates <- function(DT, col_date = "Date"){
  DT[, ':='(Year = gsub("-\\d{2}-\\d{2}", "", get(col_date)),
            YearMonth = gsub("-\\d{2}$", "", get(col_date)),
            MonthDay = gsub("\\d{4}-", "", get(col_date)))]
  return(DT)
}

#' group_in_season
#' @description  Group annual data into seasonal data 1 July to 30 June next year
#' 
#'
#' @param DT, data.table
#'
#' @return data.table with a column `Season`
#' @export
#'
#' @examples
group_in_season <- function(DT){
  
  stopifnot("Date" %in% colnames(DT))
  
  period <- range(DT$Date)
  noofyear <- diff.Date(period, unit = "year") %>% 
    as.numeric(.)/365
  startyear <- year(period[1])
  endyear <- year(period[2])
  startmd <- "-07-01"
  endmd <- "-06-30"
  noofseason <- round(noofyear, digits = 0)
  
  # Initial a vector to store the text as cmd
  cmd <- vector("character", noofseason)
  
  # Build a cmd to do conditional evaluation 
  
  for(i in 0:(noofseason)){
    # Key condition
    v <- paste0("Date >= \"" , startyear + i, startmd,"\"","&",
                "Date <= \"", startyear + i + 1, endmd, "\"",",",
                "\"", startyear +i,"/", startyear + i + 1, "\"",",")
    # Check the format 
    # cat(v)
    # Store it; must be i + 1 since R has no 0 position
    cmd[i + 1] <- v
  }
  # Collapse into one string and glue the fcase function 
  cmd <- paste0("fcase( ", paste(cmd, collapse = ""), ")")
  
  # Delete the end comma
  cmd <- gsub(",)$", ")", cmd)
  # Check format again
  cat("Check if the command format is correct\r\n", cmd)
  
  DT[, Season:= eval(parse(text = cmd))]
  return(DT)
  
  
}



process_bestfit <- function(skl_best_fit, kl_best_fit, saveTo){
  skl_best_fit = skl_best_fit[,.(Experiment, SowingDate, kl = SKL, Depth = 1L)]
  kl_best_fit[,kl := as.numeric(gsub("kl","", kl))]
  kl_best_fit = unique(kl_best_fit[, .(Experiment, SowingDate, Depth, kl)])
  best_fit_layerkl = rbindlist(list(skl_best_fit, kl_best_fit), use.names = TRUE)
  setkey(best_fit_layerkl, Experiment, SowingDate, Depth)
  
}


#' rename_cols
#' @description Rename the soilwater data. The top 20cm data has been
#'   artifically divide into two 10 cm layer. 
#'
#' @param DT data.table which has water data 
#' @param pattern the colnames for soil water content for each layer 
#'
#' @return
#' @export
#'
#' @examples
rename_cols <- function(DT, pattern = "^(?!SW)"){
  if("SWC" %in% names(DT)){
  data.table::setnames(DT, names(DT),  
                       c(grep(pattern = "^(?!SW)" , perl = TRUE, names(DT), value = TRUE), 
                         paste0("SW(", 1:22,")"), 
                         "SWC"))
  } else {
    data.table::setnames(DT, names(DT),  
                         c(grep(pattern = "^(?!SW)" , perl = TRUE, names(DT), value = TRUE), 
                           paste0("SW(", 1:22,")")))
  }
  DT
}
#' max_min
#'
#' @param x 
#'
#' @return
#' @export
#'
#' @examples
max_min <- function(x){list(DUL = max(x, na.rm = TRUE),
                            LL = min(x, na.rm = TRUE))}

#' check_resi
#'
#' @description check if the residue of the simulated and observed values are
#'   randomly placed.
#'
#' @param df
#' @param SimulationID
#' @param col_date
#' @param col_target
#'
#' @return
#' @export
#'
#' @examples
check_resi <-  function(dt, ID = 1L,  col_date = "Clock.Today", col_target ){
  
  print(ID)

  if(is.data.table(dt)){
    cols <- c(col_date, col_target)
    p <- PredObs[SimulationID == as.integer(ID)][, ..cols] %>%
      ggplot(aes_string(col_date, col_target)) +
      geom_point() + 
      theme_water() +
      ggplot2::geom_hline(yintercept = 0, color = "red")
    p
    
  } else{
    print("Only works for data.table format!")
  }

}

#' read_met_col
#'
#' @description read met col names only
#' 
#' @param path 
#' @param skip 
#' @param nrows 
#'
#' @return
#' @export
#'
#' @examples
read_met_col <- function(path = path_met, skip = 7){
  met_col <- data.table::fread(input = path, skip = skip, nrows = 1)
  met_col
}



#' exam_xlsxs
#' 
#' @note need to write unit tests
#' @param path_apX the key path to the file folder
#' @param filename file names
#'
#' @return a data frame
#' @export
#'  
#'
#'
exam_xlsxs <- function(path_apX, filename){
  df = read_excel(file.path(path_apX, filename)) %>% 
    inspect_cat(.) %>% 
    filter(col_name %in% c("Name", "SimulationName")) %>% 
    select(levels) %>% 
    unnest()
  df
}



# choose_cols --------------------------------------------------------------------

#' choose_cols
#' @description calculate the number of NAs and nrows, drop the columns are all NAs
#'
#' @param dt a data.table or data.frame
#'
#' @return a vector has colnames for the sepecific table 
#' 
#' @export
#'
#' 
choose_cols <- function(dt){
  logica = sapply(dt, function(x){
    sum(is.na(x)) == dim(dt)[1]
  })
  col_good = names(which(logica != 1))
  col_good
}



# theme -------------------------------------------------------------------

theme_water <- function(){
  theme_classic() + 
    theme(panel.border = element_rect(fill = "NA"),
          text = element_text(size = 14))
}


# fix date ----------------------------------------------------------------

#' Title
#'
#' @param df 
#'
#' @return
#' @export
#' 

fix_date <- function(df, col_Date = "Clock.Today"){
  
  df[[col_Date]] = as.Date(df[[col_Date]])
  dt = data.table::as.data.table(df)
}



# fix factors -------------------------------------------------------------

#' fix_SDorder
#' 
#' @description re-order the sowing date from 1 to 10
#' @param dt a data.table has a column named `SowingDate`
#'
#' @return
#' @export
#'
#' @examples
fix_SDorder <- function(dt){
  dt$SowingDate <- as.factor(dt$SowingDate)
  
  dt$SowingDate <-  factor(dt$SowingDate,
                           levels = levels(dt$SowingDate)[c(1, 3:10, 2)])
  return(dt)
}


