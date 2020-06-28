# Protocol

# - Load best fit from the output 
# - Set up directory structure[Set directory structure]  
# - Modify apsimx file via edit
# - Invoke **Edit**  [Invoke Apsimx]  

process_dbs <- function(dbs){
  list = sapply(dbs, read_dbtab, table = "Report", 
                USE.NAMES = TRUE, simplify = FALSE)
  
  DT = rbindlist(list, idcol = "Source")
  DT[, ':='(Experiment = regmatches(basename(Source), 
                                    regexpr("(AshleyDene|Iversen12)", 
                                            basename(Source))),
            SowingDate = regmatches(basename(Source), 
                                    regexpr("SD\\d{1,2}", 
                                            basename(Source))))]
  DT
}


#' process_list
#'
#' @param files a list of data.tables. 
#' @param keys the id variables that doesn't need to be melted
#' @param pattern a regex pattern to select multiple columns 
#'
#' @return
#' @export
#'
#' @examples
process_list <- function(files, keys = c("Experiment", "SowingDate", "SKL", "RFV"),
                         pattern = "KLmod"){
  DT = rbindlist(files)
  setkeyv(DT, cols = keys)
  value_vars = grep(pattern = pattern, colnames(DT), value = TRUE)
  id_vars = data.table::key(DT)
  cols = c(id_vars, value_vars)
  DT_long = DT[,..cols] %>% 
    melt(id.vars = id_vars, 
         measure.vars = value_vars)
  DT_long[, ':='(Layer = gsub("\\D", "", variable),
                 kl = SKL * value)]
  DT_long
}
# File structure 

#' EditApsimxLayers
#'
#' @param path path to apsimx models.exe
#' @param info path to the file has best fit paramters 
#' @param SW_DUL_LL the initial conditions of the soils
#' @param SD_tidied the sowing date treatment or other treatment?!
#' @param kls the kls calcuated from the best fit surface kl 
#'
#' @import data.table 
#' @return
#' @export
#'
#' @examples
EditApsimxLayers <- function(path, 
                             info,
                             SW_DUL_LL, 
                             SD_tidied,
                             kls){
  
# Environmental variables to control file paths
Sys.setenv("WorkingDir" = here::here())
Sys.setenv("BaseApsimxDir" = file.path(Sys.getenv("WorkingDir"), "01raw-data/ApsimxFiles/"))
Sys.setenv("MetDir" = file.path(Sys.getenv("WorkingDir"), "01raw-data/ClimateAndObserved/"))
Sys.setenv("ConfigFileDir" = file.path(Sys.getenv("WorkingDir"), "03processed-data/ConfigurationFiles/"))
Sys.setenv("CoverDataDir" = file.path(Sys.getenv("WorkingDir"), "03processed-data/CoverData/"))
Sys.setenv("SimsDir" = file.path(Sys.getenv("WorkingDir"), "03processed-data/bestfitLayerkl/"))
## Verifcation
# Construct kl ranges 
# Could be defined on the fly 
KL_layer <- 22L

#BD 
DB_AshleyDene <- c("1.150,1.150,1.310,1.310,1.950,1.950,1.950,1.950,1.950,1.950,1.950,1.950,1.950,1.950,1.950,1.950,1.950,1.950,1.950,1.950,1.950,1.950")
DB_Iversen12 <- c("1.260,1.260,1.260,1.440,1.440,1.440,1.570,1.570,1.570,1.580,1.580,1.580,1.580,1.590,1.590,1.590,1.590,1.590,1.590,1.590,1.590,1.590")

# ApsimX node paths 
## The site level configuration 
weather = "[Weather].FileName = "
Height = "[SetCropVariables].Script.MaximumHeight = "
BD = "[Soil].Physical.BD = "
## The Sowing date level configuration 

SDnode = "[SlurpSowingRule].Script.SowingDate = "
ClockStart = "[Clock].Start = "

CoverData = "[SetCropVariables].Script.CoverFile = "
initialSW = "[Soil].InitialConditions.SW = "

DUL <- "[Soil].Physical.DUL = "
SAT <- "[Soil].Physical.SAT = "

AirDry <- "[Soil].Physical.AirDry = "
LL15 <- "[Soil].Physical.LL15 = "
LL <- "[Soil].Physical.SlurpSoil.LL = "

## The kl parameter level configuration 
KL <- paste0("[Soil].Physical.SlurpSoil.KL", "[1:", KL_layer,"]"," = ")
RFV <-  paste0("[SlurpSowingRule].Script.RFV = ")
# Replacement values
# Critical order
setkey(SW_DUL_LL, Experiment, SowingDate, Depth)

t1 <- Sys.time()
# Constant
Sites <- unique(info$Experiment)
SowingDates <- unique(info$SowingDate)
for (i in Sites) {
  for (j in SowingDates) {
    
    # Site level
    ## met files 
    replacement_met <- file.path(Sys.getenv("MetDir"), paste0(i,".met"))
    ## Height
    replacement_MaxHeight <- ifelse(i == "AshleyDene", 390L, 595L)
    replacement_BD <- ifelse(i == "AshleyDene", DB_AshleyDene, DB_Iversen12)
    # Sowing date level 
    ## SD
    replacement_SD <- SD_tidied[Experiment == i & SD == j ]$Clock.Today
    ## ClockStart
    replacement_ClockStart <- paste0(replacement_SD, "T00:00:00")
    ## User provide light interception data 
    replacement_CoverData <- file.path(Sys.getenv("CoverDataDir"),paste0("CoverData", i, j, ".csv"))
    ## Soil parameters 
    replacement_initialSW <- SW_DUL_LL[Experiment == i & SowingDate == j]$SW
    replacement_DUL <- SW_DUL_LL[Experiment == i & SowingDate == j]$DUL
    replacement_SAT <- replacement_DUL
    replacement_LL <- SW_DUL_LL[Experiment == i & SowingDate == j]$LL
    replacement_AirDry <- replacement_LL
    replacement_LL15 <- replacement_LL
    
    ## The kl parameter level configuration 
    # for (skl in KL_range){
      replacement_KL <- kls[Experiment == i & SowingDate == j]$kl
      replacement_RFV <-  unique(kls[Experiment == i & SowingDate == j]$RFV)

      # Paste together ----
      
      apsimx_met <- paste0(weather, replacement_met)
      apsimx_Height <- paste0(Height, replacement_MaxHeight)
      apsimx_BD <- paste0(BD, replacement_BD)
      apsimx_SD <- paste0(SDnode, replacement_SD)
      apsimx_ClockStart <- paste0(ClockStart, replacement_ClockStart)
      apsimx_CoverData <- paste0(CoverData, replacement_CoverData)
      
      apsimx_initialSW <- paste0(initialSW, paste(replacement_initialSW,collapse = ","))
      apsimx_DUL <- paste0(DUL, paste(replacement_DUL,collapse = ","))
      apsimx_LL <- paste0(LL, paste(replacement_LL,collapse = ","))
      apsimx_KL <- paste0(KL, paste(replacement_KL,collapse = ","))
      apsimx_RFV <- paste0(RFV, replacement_RFV)
      apsimx_SAT <- paste0(SAT, paste(replacement_SAT,collapse = ","))
      apsimx_AirDry<- paste0(AirDry, paste(replacement_AirDry,collapse = ","))
      apsimx_LL15 <- paste0(LL15, paste(replacement_LL15,collapse = ","))
      
      # Write out ----
      f <- file(paste0(Sys.getenv("ConfigFileDir"),"/LayerKL_",
                       replacement_KL[1], "RFV_", replacement_RFV, i, j, ".txt"), "w")
      # Write values into the file 
      cat(apsimx_met,
          apsimx_ClockStart,
          apsimx_Height,
          apsimx_BD,
          apsimx_SD,
          apsimx_CoverData,
          apsimx_initialSW,
          apsimx_DUL,
          apsimx_KL,
          apsimx_RFV,
          apsimx_LL,
          apsimx_SAT,
          apsimx_AirDry,
          apsimx_LL15, "\r",
          sep = "\r", 
          file = f, 
          append = TRUE)
      # Close the file and clean it from memory 
      close(f)
      rm(f)
      gc()
    # }
    
  }
}

t2 <- Sys.time()
t2 - t1

# Invoke Apsimx


# Constants 
apsimx <- path
apsimx_flag <- "/Edit"
apsimx_Basefile <- file.path(Sys.getenv("BaseApsimxDir"), "20200618CalibrateLayersSlurp.apsimx")
apsimx_sims_temp <- file.path(Sys.getenv("SimsDir"), "temp.apsimx")
apsimx_sims_dir <- Sys.getenv("SimsDir")
apsimx_config <- paste0(Sys.getenv("ConfigFileDir"),"/LayerKL_")
# paste0(Sys.getenv("ConfigFileDir"),"/ConfigSKL_", SKL, "RFV_", replacement_RFV, i, j, ".txt")
# Copy the base apsimx file to a temp file in a disposable dir
system(paste('cp', apsimx_Basefile, apsimx_sims_temp))
# system(paste(apsimx, apsimx_sims_temp, apsimx_flag, paste0(apsimx_config, sites[1], SDs[1],".txt")))

t1 <- Sys.time()
for (i in Sites) {
  for (j in SowingDates) {
    replacement_KL <- info[Experiment == i & SowingDate == j]$SKL
    replacement_RFV <-  info[Experiment == i & SowingDate == j]$RFV

      # Edit the base apsimx file and save it to a new name
      ## modify the apsimx file
      modifiedName <- paste0(apsimx_sims_dir, "/LayerKL_", replacement_KL, "RFV_", replacement_RFV,  i, j, ".apsimx")
      system(paste("cp", apsimx_sims_temp, modifiedName))
      system(paste(apsimx, modifiedName, apsimx_flag, paste0(apsimx_config,  replacement_KL, "RFV_", replacement_RFV,  i, j,".txt")))
      ## rename the modified one
      # system(paste("mv", apsimx_sims_temp, paste0(apsimx_sims_dir, "/Modified", i, j, ".apsimx")))
    
  }
}
## delete the temp apsimx 
system(paste("rm", paste0(apsimx_sims_dir, "/temp*")))
t2 <- Sys.time()
t2 - t1
}



EditLayerKL_multi <- function(KL_layers, KL_range, files, path ="c:/Data/ApsimX/ApsimXLatest/Bin/Models.exe",
                        saveTo){
  # print(KL_layers)
  # print(KL_range)
  # print(files)
  for(i in KL_layers){
    for(j in KL_range){
      for(k in files){
        cat(i, j, k, "\r\n")
        autoapsimx::EditLayerKL(i, j, path = path, 
                                apsimx = k,
                                saveTo = saveTo)
      }
    }
  }
  }
