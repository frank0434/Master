



#' Title
#'
#' @param template 
#' @param Site 
#' @param SD 
#' @param apsimx 
#' @param apsimx_Basefile 
#' @param dir_metfile 
#' @param dir_cover 
#' @param dir_config 
#' @param dir_Sensitivity 
#' @param DUL_LL_range 
#' @param bulkDensity 
#' @param SowingDates 
#' @param SW_initial 
#'
#' @return
#' @export
#'
#' @examples
slurpConfig <- function(template = template, 
                        Site, SD, apsimx, apsimx_Basefile,
                        dir_metfile, dir_cover, dir_config,
                        DUL_LL_range = DUL_LL_range,
                        bulkDensity = bulkDensity, 
                        SowingDates, SW_initial) {

  replacementA_met <- file.path(dir_metfile, paste0(Site,".met"))
  
  # Sowing date level 
  ## SD
  replacementC_SD <- as.character(SowingDates[Experiment == Site & 
                                                SowingDate == SD ]$Clock.Today)
  
  replacementB_ClockStart <- paste0(replacementC_SD, "T00:00:00")
  
  ## Height
  replacementD_MaxHeight <- ifelse(Site == "AshleyDene", 390L, 595L)
  
  
  ## ClockStart
  ## User provide light interception data 
  replacementE_CoverData <- file.path(dir_cover,paste0("LAI", Site, SD, ".csv"))
  
  replacementI_initialSW <- paste(SW_initial[Experiment == Site & SowingDate == SD]$SW, 
                                  collapse = ",")
  replacementJ_SAT <- paste(DUL_LL_range[Experiment == Site & SowingDate == SD]$High.DUL, 
                            collapse = ",")
  replacementK_AirDry <- paste(DUL_LL_range[Experiment == Site & SowingDate == SD]$Low.LL, 
                               collapse = ",")
  replacementL_LL15 <- replacementK_AirDry
  replacementM_DUL <- paste(DUL_LL_range[Experiment == Site & SowingDate == SD]$SW.mean.DUL, 
                            collapse = ",")
  replacementN_LL <- paste(DUL_LL_range[Experiment == Site & SowingDate == SD]$SW.mean.LL, 
                           collapse = ",")
  BD_profile <- (bulkDensity[Experiment == Site]$BD_kg.m3)/1000
  replacementO_BD <- paste(BD_profile, 
                           collapse = ",")
  replacevalues <- grep("replacement.+", ls(), value = TRUE)
  values <- mget(replacevalues)
  config <- paste0(template, "=", values)
  
  basename <- paste0(Site, SD)
  outputpath <- file.path(dir_config, paste0(basename, ".txt"))
  
  writeLines(text = config, con = outputpath)  
  cat("Configuration file write into", outputpath, "\r\n")
  ## New name
  modifiedName <- file.path(dir_Sensitivity, paste0(basename, ".apsimx"))
  ## Modify base to generate new apsimx files 
  system(paste("cp", apsimx_Basefile, modifiedName))
  system(paste(apsimx, modifiedName, "/Edit",outputpath))
  return(modifiedName)

}

##' .. content for \description{} (no empty lines) ..
##'
##' .. content for \details{} ..
##'
##' @title

##' @return
##' @author frank0434
##' @export
build_config <- function(template = template, Site, SD,apsimx,apsimx_Basefile,
                         dir_metfile, dir_cover, dir_config,dir_Sensitivity,
                         DUL_LL_range = DUL_LL_range,
                         bulkDensity = bulkDensity, 
                         SowingDates, SW_initial) {
  # Process the sampledvalues to get the correct meta
  # meta <- unique(sampledValus$meta)
  # meta <- unlist(strsplit(meta, split = "_"))
  # Site <- meta[1]
  # SD <- meta[2]
  # Layer.no <- as.integer(gsub("Layer", "", meta[3]))
  # simNo <- nrow(sampledValus)
  # template <- readLines(dir_tempalte)
  replacementA_met <- file.path(dir_metfile, paste0(Site,".met"))
  
  # Sowing date level 
  ## SD
  replacementC_SD <- as.character(SowingDates[Experiment == Site & 
                                                SowingDate == SD ]$Clock.Today)
  
  replacementB_ClockStart <- paste0(replacementC_SD, "T00:00:00")
  
  ## Height
  replacementD_MaxHeight <- ifelse(Site == "AshleyDene", 390L, 595L)
  
  
  ## ClockStart
  ## User provide light interception data 
  replacementE_CoverData <- file.path(dir_cover,paste0("LAI", Site, SD, ".csv"))
  
  replacementI_initialSW <- paste(SW_initial[Experiment == Site & SowingDate == SD]$SW, 
                                  collapse = ",")
  replacementJ_SAT <- paste(DUL_LL_range[Experiment == Site & SowingDate == SD]$High.DUL, 
                            collapse = ",")
  replacementK_AirDry <- paste(DUL_LL_range[Experiment == Site & SowingDate == SD]$Low.LL, 
                               collapse = ",")
  replacementL_LL15 <- replacementK_AirDry
  replacementM_DUL <- paste(DUL_LL_range[Experiment == Site & SowingDate == SD]$SW.mean.DUL, 
                            collapse = ",")
  replacementN_LL <- paste(DUL_LL_range[Experiment == Site & SowingDate == SD]$SW.mean.LL, 
                           collapse = ",")
  BD_profile <- (bulkDensity[Experiment == Site]$BD_kg.m3)/1000
  replacementO_BD <- paste(BD_profile, 
                           collapse = ",")
  replacevalues <- grep("replacement.+", ls(), value = TRUE)
  values <- mget(replacevalues)
  config <- paste0(template, "=", values)
  
  basename <- paste0(Site, SD)
  outputpath <- file.path(dir_config, paste0(basename, ".txt"))
  
  writeLines(text = config, con = outputpath)  
  cat("Configuration file write into", outputpath, "\r\n")
  ## New name
  modifiedName <- file.path(dir_Sensitivity, paste0(basename, ".apsimx"))
  ## Modify base to generate new apsimx files 
  system(paste("cp", apsimx_Basefile, modifiedName))
  system(paste(apsimx, modifiedName, "/Edit",outputpath))
  return(modifiedName)
  ## Soil parameters 
  # Layber.no <- 1L
  # replacedLayer <- c(rep("", 15), rep(paste0("[", Layer.no, "]"), 3))
  # 
  # for( i in seq_len(simNo)){
  #   
  #   replacementF_KRL <- sampledValus[i,]$KLR 
  #   replacementG_RFV <- sampledValus[i,]$RFV
  #   replacementH_SKL <- sampledValus[i,]$SKL
  #   
  #   replacementP_BD <- sampledValus[i,]$BD1
  #   replacementQ_DUL <- sampledValus[i,]$DUL1
  #   replacementR_LL <- sampledValus[i,]$LL1
  #   
  #   
  #   replacevalues <- grep("replacement.+", ls(), value = TRUE)
  #   values <- mget(replacevalues)
  #   config <- paste0(template,replacedLayer, "=", values)
  #   
  #   basename <- paste0(Site, SD,"Layer", Layer.no, "Path",i)
  #   outputpath <- file.path(dir_config, paste0(basename, ".txt"))
  #   
  #   writeLines(text = config, con = outputpath)  
  #   cat("Configuration file write into", outputpath, "\r\n")
  #   ## New name
  #   modifiedName <- file.path(dir_Sensitivity, paste0(basename, ".apsimx"))
  #   ## Modify base to generate new apsimx files 
  #   system(paste("cp", apsimx_Basefile, modifiedName))
  #   system(paste(apsimx, modifiedName, "/Edit",outputpath))
  #   return(modifiedName)
  #   # cat(modifiedName, "\r\n")
  # }

  
}

build_apsimx <- function(template, apsimx, apsimx_Basefile,
                         dir_metfile, cover, observed, dir_config = dir_config,
                         bulkDensity,SowingDates,SW_initial,DUL_LL_range,
                         dir_simulations){
  # Process the sampledvalues to get the correct meta
  meta <- unlist(strsplit(cover, split = "_"))
  Site <- meta[2]
  SD <- gsub(".csv", "", meta[3])
  
  replacementA_met <- file.path(dir_metfile, paste0(Site,".met"))
  
  # Sowing date level 
  ## SD
  replacementC_SD <- as.character(SowingDates[Experiment == Site & 
                                                SowingDate == SD ]$Clock.Today)
  
  replacementB_ClockStart <- paste0(replacementC_SD, "T00:00:00")
  
  ## Height
  replacementD_MaxHeight <- ifelse(Site == "AshleyDene", 390L, 595L)
  
  
  ## ClockStart
  ## User provide light interception data 
  replacementE_CoverData <- cover
  
  replacementI_initialSW <- paste(SW_initial[Experiment == Site &
                                               SowingDate == SD ]$SW, 
                                  collapse = ",")
  replacementJ_SAT <- paste(DUL_LL_range[Experiment == Site & SowingDate == SD]$SAT, 
                            collapse = ",")
  replacementK_AirDry <- paste(DUL_LL_range[Experiment == Site & SowingDate == SD]$SW.LL15, 
                               collapse = ",")
  replacementL_LL15 <- replacementK_AirDry
  replacementM_DUL <- paste(DUL_LL_range[Experiment == Site & SowingDate == SD]$SW.DUL, 
                            collapse = ",")
  replacementN_LL <- paste(DUL_LL_range[Experiment == Site & SowingDate == SD]$SW.LL, 
                           collapse = ",")
  BD_profile <- (bulkDensity[Experiment == Site]$BD_kg.m3)/1000
  replacementO_BD <- paste(BD_profile, 
                           collapse = ",")
  replacementP_observation <- observed
  replacevalues <- grep("replacement.+", ls(), value = TRUE)
  values <- mget(replacevalues)
  config <- paste0(template, "=", values)
  
  basename <- paste0(Site, "_",SD)
  outputpath <- file.path(dir_config, paste0(basename, ".txt"))
  
  writeLines(text = config, con = outputpath)  
  cat("Configuration file write into", outputpath, "\r\n")
  ## New name
  modifiedName <- file.path(dir_simulations, paste0(basename, ".apsimx"))
  ## Modify base to generate new apsimx files 
  system(paste("cp", apsimx_Basefile, modifiedName))
  system(paste(apsimx, modifiedName, "/Edit",outputpath))
  return(modifiedName)
  
}


#' build_optimSlurp
#' @description for modifying the slurp only regarding to surface kl.
#'
#' @param template 
#' @param dir_optim 
#' @param dir_config 
#' @param KL_range 
#' @param apsimx 
#' @param apsimx_Basefile 
#'
#' @return
#' @export
#'
#' @examples
build_optimSlurp <- function(template = templatePhase2, 
                 dir_optim = dir_simulations, 
                 dir_config = dir_config, 
                 KL_range = SKL_Range,
                 apsimx = path_apsimx, 
                 apsimx_Basefile = apsimxPhase1){
  
  name <- gsub("\\.apsimx", "", basename(apsimx_Basefile))
  for (skl in KL_range){
    
    config <- paste0(template, "=", skl)
    output <-  paste0(dir_config,"/ConfigSKL_", skl[1], name, ".txt")
    writeLines(text = config, con = output)  
    
    # Edit the base apsimx file and save it to a new name
    ## modify the apsimx file
    modifiedName <- paste0(dir_optim, "/ModifiedSKL_", skl, name, ".apsimx")
    system(paste("cp", apsimx_Basefile, modifiedName))
    system(paste(apsimx, modifiedName, "/Edit", output))
    # system(paste(apsimx, modifiedName))
  }
  
  
}
