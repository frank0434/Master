# Aim: output the DUL LL and SW for each layer in each sowing dates for two sites. 

# Depends on the .2_Data_EDA.Rmd

swSD1 <- SW_DUL_LL[SowingDate == "SD3" & Experiment == "AshleyDene"]$SW
apsimx_sw <- paste0(".Simulations.New Zealand.AshleyDene.Factors.SowingDate.SD3.ADsoils.InitialConditions.SW=",
                    paste(swSD1,collapse = ","))
# apsimx_sw <- paste(swSD1,collapse = ",")
# names(apsimx_sw) <- ".Simulations.NewZealand.AshleyDene.Factors.SowingDate.SD1.Soil.InitialConditions.SW"
apsimx_sw %>% 
  writeLines(., con = "../03processed-data/configSoilWat.txt")
#path to apsimx 
apsimx <- "C:/Data/ApsimxLatest/ApsimX/Bin/Models.exe"
apsimx_flag <- "/Edit"
apsimx_file <- "C:/Data/Master/01raw-data/ApsimxFiles/20200513Base.apsimx"
apsimx_sims_temp <- "C:/Data/Master/03processed-data/apsimxFiles/temp.apsimx"
apsimx_sims_dir <- "C:/Data/Master/03processed-data/apsimxFiles/"
apsimx_config <- "C:/Data/Master/03processed-data/configSoilWat"

# copy file into a new dir and rename it temp 
system(paste("cp", apsimx_file, apsimx_sims_temp))
# modify the apsimx file 
system(paste(apsimx, apsimx_sims_temp, apsimx_flag, apsimx_config))
# rename the modified one
system(paste("mv", apsimx_sims_temp, paste0(apsimx_sims_dir, "Modified.apsimx")))
# delete the temp apsimx 
system(paste("rm", paste0(apsimx_sims_dir, "temp*")))

sites <- unique(SW_initials$Experiment)
SDs <- paste0("SD", 1:10)

for(j in sites){
  f <- file(paste0(apsimx_config, j,".txt"), "w")
  for(i in paste0("SD", 1:10)){
    SDsw <- SW_DUL_LL[SowingDate == i & Experiment == j]$SW
    SDDUL <- SW_DUL_LL[SowingDate == i & Experiment == j]$DUL
    SDLL <- SW_DUL_LL[SowingDate == i & Experiment == j]$LL
    # SDPAWC <- SW_DUL_LL[SowingDate == i & Experiment == j]$PAWC
    apsimx_sw <- paste0(".Simulations.New Zealand.AshleyDene.Factors.SowingDate.",
                        i,
                        ".ADsoils.InitialConditions.SW = ",
                        paste(SDsw,collapse = ","))
    apsimx_DUL <- paste0(".Simulations.New Zealand.AshleyDene.Factors.SowingDate.",
                         i,
                         ".ADsoils.Physical.DUL = ",
                         paste(SDDUL,collapse = ","))
    apsimx_LL <- paste0(".Simulations.New Zealand.AshleyDene.Factors.SowingDate.",
                        i,
                        ".ADsoils.Physical.LucerneSoil.LL = ",
                        paste(SDLL,collapse = ","))
    apsimx_LL15 <- paste0(".Simulations.New Zealand.AshleyDene.Factors.SowingDate.",
                          i,
                          ".ADsoils.Physical.LL15 = ",
                          paste(SDLL,collapse = ","))
    apsimx_SAT <- paste0(".Simulations.New Zealand.AshleyDene.Factors.SowingDate.",
                         i,
                         ".ADsoils.Physical.SAT = ",
                         paste(SDDUL,collapse = ","))
    
    cat(apsimx_sw,
        apsimx_DUL,
        apsimx_LL,
        apsimx_LL15,
        apsimx_SAT,"\r",
        sep = "\r", 
        file = f, 
        append = TRUE)
    
  }
  close(f)
  rm(f)
  gc()
}


for(j in sites){
  # copy file into a new dir and rename it temp 
  system(paste("cp", apsimx_file, apsimx_sims_temp))
  # modify the apsimx file 
  system(paste(apsimx, apsimx_sims_temp, apsimx_flag, paste0(apsimx_config, j,".txt")))
  # rename the modified one
  system(paste("mv", apsimx_sims_temp, paste0(apsimx_sims_dir, "Modified", j, ".apsimx")))
  # delete the temp apsimx 
  system(paste("rm", paste0(apsimx_sims_dir, "temp*")))
}


