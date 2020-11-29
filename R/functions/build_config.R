##' .. content for \description{} (no empty lines) ..
##'
##' .. content for \details{} ..
##'
##' @title

##' @return
##' @author frank0434
##' @export
build_config <- function(template = template, sampledValus = sampledvalues,
                         dir_metfile, dir_cover, dir_config,dir_Sensitivity,
                         DUL_LL_range = DUL_LL_range,
                         bulkDensity = bulkDensity, 
                         SowingDates, SW_initial) {
  # Process the sampledvalues to get the correct meta
  meta <- unique(sampledValus$meta)
  meta <- unlist(strsplit(meta, split = "_"))
  Site <- meta[1]
  SD <- meta[2]
  Layer.no <- as.integer(gsub("Layer", "", meta[3]))
  simNo <- nrow(sampledValus)
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
  BD_prifle <- (bulkDensity[Experiment == Site]$BD_kg.m3)/1000
  replacementO_BD <- paste(BD_prifle, 
                           collapse = ",")
  
  ## Soil parameters 
  # Layber.no <- 1L
  replacedLayer <- c(rep("", 15), rep(paste0("[", Layer.no, "]"), 3))
  
  for( i in seq_len(simNo)){
    
    replacementF_KRL <- sampledValus[i,]$KLR 
    replacementG_RFV <- sampledValus[i,]$RFV
    replacementH_SKL <- sampledValus[i,]$SKL
    
    replacementP_BD <- sampledValus[i,]$BD1
    replacementQ_DUL <- sampledValus[i,]$DUL1
    replacementR_LL <- sampledValus[i,]$LL1
    
    
    replacevalues <- grep("replacement.+", ls(), value = TRUE)
    values <- mget(replacevalues)
    config <- paste0(template,replacedLayer, "=", values)
    
    basename <- paste0(Site, SD,"Layer", Layer.no, "Path",i)
    outputpath <- file.path(dir_config, paste0(basename, ".txt"))
    
    writeLines(text = config, con = outputpath)  
    cat("Configuration file write into", outputpath, "\r\n")
    ## New name
    # modifiedName <- file.path(dir_Sensitivity, paste0(basename, ".apsimx"))
    ## Modify base to generate new apsimx files 
    # system(paste("cp", apsimx_Basefile, modifiedName))
    # system(paste(apsimx, modifiedName, "/Edit",outputpath))
    # return(modifiedName)
    # cat(modifiedName, "\r\n")
  }

  
}

