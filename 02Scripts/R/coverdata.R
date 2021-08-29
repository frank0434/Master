
source("02Scripts/R/packages.R")
source("02Scripts/R/functions.R")
path_richard = "c:/Users/cflfcl/Dropbox/Data/APSIM_Sim.xlsx"
sowingDates <- readRDS(here::here("_targets/objects/sowingDates"))
met_Iversen12 <- readRDS(here::here("_targets/objects/met_Iversen12_SD1"))
met_AshleyDene <- readRDS(here::here("_targets/objects/met_AshleyDene_SD1"))
LAI_Height <- read_Sims(path = path_richard, source = "biomass")

#### Already in the read_sims function
# biomass_cols <- c('Experiment', 'Clock.Today', 'SowingDate', 'Rep',
#                   'Plot', 'Rotation.No.', 'Harvest.No.', 'Height','LAImod')

# LAI_Height <-  biomass[Seed== 'CS' & Harvest.No.!= "Post"
#                        ][,..biomass_cols
#                          ][, unlist(list(lapply(.SD, mean, na.rm = TRUE)), recursive = FALSE),
#                            by = .(Experiment, SowingDate, Clock.Today),
#                            .SDcols = c("Height", "LAImod")]
######
LAI_Height_SD <- merge.data.table(LAI_Height, sowingDates, 
                                  by = c("Experiment", "Clock.Today" , "SowingDate"), 
                                  all= TRUE)[,
                                             ':='(LAImod = ifelse(is.na(LAImod), 0, LAImod),
                                                  Height = ifelse(is.nan(Height), NA, Height))]

LAI_wide <- dcast.data.table(LAI_Height_SD, 
                             Experiment + Clock.Today ~ SowingDate, 
                             value.var = "LAImod" )

accumTT <- rbindlist(list(met_Iversen12[, Experiment := "Iversen12"],
                          met_AshleyDene), use.names = TRUE)[,.(Experiment, Clock.Today, AccumTT)]
DT <- merge.data.table(accumTT, LAI_wide, by = c("Experiment", "Clock.Today"), 
                 all.x = TRUE)

DT <- melt.data.table(data = DT, 
                      id.vars = c("Experiment", "Clock.Today", "AccumTT"), 
                      value.name = "LAI",
                      variable.name = "SowingDate", variable.factor = FALSE)

DT[, LAI:= na.approx(LAI, AccumTT, na.rm = FALSE) , by = .(Experiment, SowingDate) ]

DT[, ':='(k = 0.94)
   ][Experiment == "AshleyDene" & Clock.Today %between% c( '2011-11-30','2012-03-01'),
     k:= 0.66][, LI := 1 - exp(-k * LAI) ]



DT %>%
  ggplot(aes(Clock.Today, k)) +
  geom_point() +
  facet_wrap(~ Experiment)

DT %>%
  ggplot(aes(Clock.Today, LI, color = SowingDate)) +
  geom_point() +
  facet_wrap(~ Experiment)

# slurp need LAI WITH k

# plot(na.approx(DT$SD1, x = DT$AccumTT, na.rm = FALSE))
DT %>% 
  ggplot(aes(Clock.Today, LAI, color = SowingDate)) +
  geom_point() +
  geom_line()+
  facet_wrap(~ Experiment)

