
source("R/packages.R")
source("R/functions/functions.R")
# Define directories ------------------------------------------------------

dir_tempalte <- here::here("Data/ApsimxFiles/MorrisSlurpTemplateFirstPhase.txt")
dir_tempalte2 <- here::here("Data/ApsimxFiles/MorrisSlurpTemplateSecondPhase.txt")
dir_met <- here::here("Data/ClimateAndObserved")
dir_cover <- here::here("Data/ProcessedData/CoverData")
dir_config <- here::here("Data/ProcessedData/ConfigurationFiles/")
dir_Sensitivity <- here::here("Data/ProcessedData/Sensitivity")
path_BD <- here::here("Data/BulkDensity.xlsx")

## Apsimx executable
apsimx <- "C:/Data/ApsimX/ApsimXLatest/Bin/Models.exe"
## The flag
apsimx_flag <- "/Edit"
## The base apsimx file 
apsimx_Basefile <- here::here("Data/ApsimxFiles/20201102BaseSlurpForSA.apsimx")

# Define parameters -------------------------------------------------------

## CAUTIONS - Order matters
params <- c("BD1","DUL1","LL1","SKL","KLR","RFV")
names(params) <- paste0("param", seq(1, length(params)))

# Define morris path ------------------------------------------------------

paths <- 50L
# Load the range of DUL and LL --------------------------------------------
targets::tar_load("DUL_LL_range")

## Treatments 

Site <- "AshleyDene"
SD <- "SD2"
Layer <- 1L
## BD ranges from Graham et al 2019
bulkDensity <- as.data.table(read_excel(path = path_BD))
para1.Low <- bulkDensity[Experiment == Site & Depth == Layer][['Low']]/1000
para1.High <- bulkDensity[Experiment == Site & Depth == Layer][['High']]/1000



## DUL and LL - From Richard PhD Expt
para2.Low <- DUL_LL_range[Experiment == Site & 
                          SowingDate == SD & 
                          Depth == Layer][["Low.DUL"]]
para2.High <- DUL_LL_range[Experiment == Site & 
                           SowingDate == SD & 
                           Depth == Layer][["High.DUL"]]

para3.Low <- DUL_LL_range[Experiment == Site & 
                         SowingDate == SD & 
                         Depth == Layer][["Low.LL"]]
para3.High <- DUL_LL_range[Experiment == Site & 
                          SowingDate == SD & 
                          Depth == Layer][["High.LL"]]
## SKL, KLR and RFV # From Edmar et al 2018
para4.Low <- 0.01 
para4.High <- 0.11

para5.Low <- 0.0005 
para5.High <- 0.01

para6.Low <- 5
para6.High <- 70

# Build up the parameters  ------------------------------------------------

# params <- sapply(grep("para\\d$", x = ls(), value = TRUE), get, simplify = TRUE)

names(params)
# Define the range for feeding into morris --------------------------------

#Careful the value orders.
para.low <- as.numeric(sapply(grep(".+Low$", x = ls(), value = TRUE),get, simplify = TRUE))

para.high <- as.numeric(sapply(grep(".+High$", x = ls(), value = TRUE),get, simplify = TRUE))


# Build basic configuration files & Modify apsimx to new ones -------------------
## Read the template

  template <- readLines(dir_tempalte)
replacementA_met <- file.path(dir_met, paste0(Site,".met"))

# Sowing date level 
## SD
targets::tar_load("sowingDates")
targets::tar_load("SW_initials")

replacementC_SD <- as.character(sowingDates[Experiment == Site & SowingDate == SD ]$Clock.Today)

replacementB_ClockStart <- paste0(replacementC_SD, "T00:00:00")

## Height
replacementD_MaxHeight <- ifelse(Site == "AshleyDene", 390L, 595L)


## ClockStart
## User provide light interception data 
replacementE_CoverData <- file.path(dir_cover,paste0("LAI", Site, SD, ".csv"))

replacementI_initialSW <- paste(SW_initials[Experiment == Site & SowingDate == SD]$SW, 
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

replacevalues <- grep("replacement.+", ls(), value = TRUE)
values <- sapply(replacevalues, get, simplify = TRUE, USE.NAMES = FALSE)
config <- paste0(template, "=", values)

basename <- paste0(Site, SD)
outputpath <- file.path(dir_config, paste0(basename, ".txt"))

writeLines(text = config, con = outputpath)  
cat("Configuration file write into", outputpath, "\r\n")
modifiedName <- file.path(dir_Sensitivity, paste0(basename, ".apsimx"))
## Modify base to generate new apsimx files 
system(paste("cp", apsimx_Basefile, modifiedName))
system(paste(apsimx, modifiedName, apsimx_flag,outputpath))

# Build the morris model  -------------------------------------------------


apsimMorris<-morris(model=NULL
                    ,params #string vector of parameter names
                    ,paths #no of paths within the total parameter space
                    ,design=list(type="oat",levels=21,grid.jump=5)
                    ,binf=para.low #min for each parameter
                    ,bsup=para.high #max for each parameter
                    ,scale=T
)


# Extract the sampled values  ---------------------------------------------
sampledValus <- as.data.frame(apsimMorris$X)
simNo <- nrow(sampledValus)


# Simulation switch -------------------------------------------------------

Run_generator <- FALSE # If TRUE, Run create apsimx files
Run_simulation <- FALSE # If TRUE, Run simulation files
if(isTRUE(Run_generator)){
  
  template2 <- readLines(dir_tempalte2)
## Soil parameters 
Layber.no <- 1L
replacedLayer <- c(rep("", 3), rep(paste0("[", Layber.no, "]"), 3))

for( i in seq_len(simNo)){
  
  secondPhaseF_KRL <- sampledValus[i,]$KLR 
  secondPhaseG_RFV <- sampledValus[i,]$RFV
  secondPhaseH_SKL <- sampledValus[i,]$SKL
  
  secondPhaseP_BD <- sampledValus[i,]$BD1
  secondPhaseQ_DUL <- sampledValus[i,]$DUL1
  secondPhaseR_LL <- sampledValus[i,]$LL1

 
  replacevalues <- grep("secondPhase.+", ls(), value = TRUE)
  values <- sapply(replacevalues, get, simplify = TRUE, USE.NAMES = FALSE)
  config <- paste0(template2,replacedLayer, "=", values)
  
  basename2nd <- paste0(Site, SD,"Layer", Layer, "Path",i)
  outputpath <- file.path(dir_config, paste0(basename2nd, ".txt"))

  writeLines(text = config, con = outputpath)  
  cat("Configuration file write into", outputpath, "\r\n")
  ## New name
  dir_2nd <- file.path(dir_Sensitivity, basename)
  dir.create(dir_2nd, showWarnings = FALSE)
  modifiedName2nd <- file.path(dir_2nd, paste0(basename2nd, ".apsimx"))
  ## Modify base to generate new apsimx files 
  system(paste("cp", modifiedName, modifiedName2nd))
  system(paste(apsimx, modifiedName2nd, apsimx_flag,outputpath))
}

}

# Run simulations  --------------------------------------------------------
## Run simulations in power shell or powerplant might be a good option


# Extract simulation results  ---------------------------------------------
file.info(path = file.path(dir_Sensitivity, paste0(Site, SD)), pattern = ".db$")

list <- vector("list", length = simNo)
for( i in seq_len(simNo)){
  basename <- paste0(Site, SD,"Layer", Layer, "Path",i)
  sims <- autoapsimx::read_dbtab(file.path(dir_Sensitivity, paste0(Site, SD),paste0(basename, ".db")), table = "Report")
  sims <- sims[, SimulationID := i]
  list[[i]] <- sims
  
  
}
Output <- data.table::rbindlist(list, use.names = TRUE)

# Calculate ee and stats --------------------------------------------------

year2010 <- Output[Clock.Today.Year == 2010][, .(SW1_2010 = SW1)]
year2011 <- Output[Clock.Today.Year == 2011][, .(SW1_2011 = SW1)]
year2012 <- Output[Clock.Today.Year == 2012][, .(SW1_2012 = SW1)]

year2010_allstats <- morrisEE(Output = year2010, variable = "SW1_2010",apsimMorris = apsimMorris)

year2011_allstats <- morrisEE(Output = year2011, variable = "SW1_2011",apsimMorris = apsimMorris)
year2012_allstats <- morrisEE(Output = year2012, variable = "SW1_2012",apsimMorris = apsimMorris)

ggplot(year2010_allstats$stats, aes(mustar, sigma, color = param)) + 
  geom_point(size = 5) +
  ggtitle("SW1_2010")
paramsNos <- length(params)
pallete <- palette("R3")[1:paramsNos]
names(pallete) <- params
setDT(year2010_allstats$pathanalysis) %>% 
  melt.data.table(id.vars = c("variable", "path"),
                  value.name = "mu.star",
                  variable.factor = FALSE, 
                  variable.name = "parameters") %>% 
  ggplot(aes(path, mu.star, color = parameters)) +
  geom_point(size = 5)+
  geom_line(size = 1)

ggplot(year2011_allstats, aes(mustar, sigma, color = param)) + 
  geom_point(size = 5)+
  ggtitle("SW1_2011")

ggplot(year2012_allstats, aes(mustar, sigma, color = param)) + 
  geom_point(size = 5)+
  ggtitle("SW1_2012")


allStats <- morrisEE(Output = Output, variable = "SW1",apsimMorris = apsimMorris)


ggplot(allStats, aes(mustar, sigma, color = param)) + 
  geom_point(size = 5)
# Calculate ee and stats seasonal basis ---------------------------------
Output <- group_in_season(Output[, Date:=Clock.Today])
Output[]
season1 <- morrisEE(Output = Output[Season == "2010/2011"], variable = "SWmm(1)",apsimMorris = apsimMorris)
season2 <- morrisEE(Output = Output[Season == "2011/2012"], variable = "SWmm(1)",apsimMorris = apsimMorris)
season3 <- morrisEE(Output = Output[Season == "2012/2013"], variable = "SWmm(1)",apsimMorris = apsimMorris)

ggplot(season1$stats, aes(mustar, sigma, color = param)) + 
  geom_point(size = 5) +
  ggtitle("SW1 Season 2010/2011")
ggplot(season2$stats, aes(mustar, sigma, color = param)) + 
  geom_point(size = 5) +
  ggtitle("SW1 Season 2011/2012")

linesize <- 0.5
setDT(season1$pathanalysis) %>% 
  melt.data.table(id.vars = c("variable", "path"),
                  value.name = "mu.star",
                  variable.factor = FALSE, 
                  variable.name = "parameters") %>% 
  ggplot(aes(path, mu.star, color = parameters)) +
  geom_point(size = 1)+
  geom_line(size = linesize)+theme_water()+
  ggtitle("SW1 Season 2010/2011")

setDT(season2$pathanalysis) %>% 
  melt.data.table(id.vars = c("variable", "path"),
                  value.name = "mu.star",
                  variable.factor = FALSE, 
                  variable.name = "parameters") %>% 
  ggplot(aes(path, mu.star, color = parameters)) +
  geom_point(size = 1)+
  geom_line(size = linesize)+theme_water()+
  ggtitle("SW1 Season 2011/2012")
