# Protocol

# - Load data from sqlite   
# - Set constants. e.g. colours and keys  
# - Set target  
# Key outcomes:   
#   - Initial soil water content[Initial soil water]      
# - A set of DUL[DUL AND LL]  
# - A set of LL[DUL AND LL]  
# - Calculation and summarising  
# - Joining[Combine Soil Paras]  
# - Set up directory structure[Set directory structure]  
# - Invoke **Edit**  [Invoke Apsimx]  



# File structure 

EditApsimx <- function(SW_DUL_LL, SD_tidied){

# Environmental variables to control file paths
Sys.setenv("WorkingDir" = here::here())
Sys.setenv("BaseApsimxDir" = file.path(Sys.getenv("WorkingDir"), "01raw-data/ApsimxFiles/"))
Sys.setenv("MetDir" = file.path(Sys.getenv("WorkingDir"), "01raw-data/ClimateAndObserved/"))
Sys.setenv("ConfigFileDir" = file.path(Sys.getenv("WorkingDir"), "03processed-data/ConfigurationFiles/"))
Sys.setenv("CoverDataDir" = file.path(Sys.getenv("WorkingDir"), "03processed-data/CoverData/"))
Sys.setenv("SimsDir" = file.path(Sys.getenv("WorkingDir"), "03processed-data/apsimxFiles/"))
## Verifcation
# Sys.getenv("MetDir")
# list.files(Sys.getenv("SimsDir"))


# Construct kl ranges 

KL_range <- seq(0.005, 0.11, by = 0.005)
# Could be defined on the fly 
KL_layer <- 22L
# length(SW_DUL_LL[Experiment == "AshleyDene" & SowingDate == "SD1"]$Depth)
# SKLs <- lapply(KL_range, function(x) rep(x, times = KL_layer))
# names(SKLs) <- KL_range

#BD 
DB_AshleyDene <- c("1.150,1.150,1.310,1.310,1.950,1.950,1.950,1.950,1.950,1.950,1.950,1.950,1.950,1.950,1.950,1.950,1.950,1.950,1.950,1.950,1.950,1.950")
DB_Iversen12 <- c("1.260,1.260,1.260,1.440,1.440,1.440,1.570,1.570,1.570,1.580,1.580,1.580,1.580,1.590,1.590,1.590,1.590,1.590,1.590,1.590,1.590,1.590,1.590")



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



# Replacement values


# SW_DUL_LL = drake::readd(SW_DUL_LL)
# SD_tidied = drake::readd(SD_tidied)
# Critical order
setkey(SW_DUL_LL, Experiment, SowingDate, Depth)



t1 <- Sys.time()
# Constant
sites <- unique(SD_tidied$Experiment)
SDs <- paste0("SD", 1:10)

for (i in sites) {
  for (j in SDs) {
    
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
    for (skl in KL_range){
      replacement_KL <- skl
      
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
      apsimx_SAT <- paste0(SAT, paste(replacement_SAT,collapse = ","))
      apsimx_AirDry<- paste0(AirDry, paste(replacement_AirDry,collapse = ","))
      apsimx_LL15 <- paste0(LL15, paste(replacement_LL15,collapse = ","))
      
      # Write out ----
      f <- file(paste0(Sys.getenv("ConfigFileDir"),"/ConfigSKL_", skl[1], i, j, ".txt"), "w")
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
    }
    
  }
}

t2 <- Sys.time()
t2 - t1

# Invoke Apsimx


# Constants 
apsimx <- "C:/Data/ApsimX/ApsimXLatest/Bin/Models.exe"
apsimx_flag <- "/Edit"
apsimx_Basefile <- file.path(Sys.getenv("BaseApsimxDir"), "20200517BaseSlurp.apsimx")
apsimx_sims_temp <- file.path(Sys.getenv("SimsDir"), "temp.apsimx")
apsimx_sims_dir <- Sys.getenv("SimsDir")
apsimx_config <- paste0(Sys.getenv("ConfigFileDir"),"/ConfigSKL_")
paste0(Sys.getenv("ConfigFileDir"),"/ConfigSKL_", skl[1], i, j, ".txt")
# Copy the base apsimx file to a temp file in a disposable dir
system(paste('cp', apsimx_Basefile, apsimx_sims_temp))
# system(paste(apsimx, apsimx_sims_temp, apsimx_flag, paste0(apsimx_config, sites[1], SDs[1],".txt")))

t1 <- Sys.time()
for(j in sites){
  for(i in SDs){
    for (skl in KL_range){
      # Edit the base apsimx file and save it to a new name
      ## modify the apsimx file
      modifiedName <- paste0(apsimx_sims_dir, "/ModifiedSKL_", skl, j, i, ".apsimx")
      system(paste("cp", apsimx_sims_temp, modifiedName))
      system(paste(apsimx, modifiedName, apsimx_flag, paste0(apsimx_config,  skl, j, i,".txt")))
      ## rename the modified one
      # system(paste("mv", apsimx_sims_temp, paste0(apsimx_sims_dir, "/Modified", j, i, ".apsimx")))
    }
  }
}
## delete the temp apsimx 
system(paste("rm", paste0(apsimx_sims_dir, "/temp*")))
t2 <- Sys.time()
t2 - t1
}