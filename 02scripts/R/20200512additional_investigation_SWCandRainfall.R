# Aim: investigate the mismatch of DUL and LL calulation for different layers 

# possible because of large rainfall event? 
# refer to page 135 in the thesis
# "In Figure 6.2B VWC was modified (∙∙∙∙∙) to account f or f our d ays of 
# observed water ponding following a ~60 mm rainfall event when soil was already at DUL""
met_AD <- dbReadTable(con, "met_AshleyDene", check.names = FALSE) %>% 
  as.data.table()
met_AD[year == 2011][, day:=as.Date(day, origin = "2011-01-01")][day == "2011-06-25"]

# depend on the objects in .2_Data_EDA to be run 
water[Clock.Today > "2011-08-20" & Clock.Today < "2011-10-20"
      ][, lapply(.SD, mean, na.rm = TRUE), by = id_vars, .SDcols = value_vars # average 4 reps
        ][, unlist(lapply(.SD, max_min), recursive = FALSE), by = .(Experiment), .SDcols = value_vars]


# Check with Richard's calculation 
my_calc <- water[, lapply(.SD, mean, na.rm = TRUE), by = id_vars, .SDcols = "SWC"] # average 4 reps
Richard_calc <- read_excel("C:/Users/cflfcl/Dropbox/Data/APSIM_Sim.xlsx", "SimPhD_All.Obs", skip = 5)
Richard_calc_names <- read_excel("C:/Users/cflfcl/Dropbox/Data/APSIM_Sim.xlsx", "SimPhD_All.Obs", skip = 4, n_max = 1)
colnames(Richard_calc) <- colnames(Richard_calc_names)
DT_Richard_calc <- setDT(Richard_calc)[,. (Experiment = Site, Clock.Today = Date, SowingDate = Treat, SWC = as.numeric(SWC230cm))][!is.na(SWC)]
DT_Richard_calc
round(my_calc$SWC - DT_Richard_calc$SWC) # IDENTICAL IF RETUREN ALL 0



# additional check on the outliers of mean value after grouped by Experiment, SowingDate and Clock.Today

p <- DUL_LL %>% 
  melt(id_vars) %>% 
  .[, variable := fct_relevel(variable, paste0("SW(",1:23, ")"))] %>%
  ggplot(aes(Clock.Today, value, group = Clock.Today)) +
  geom_boxplot(outlier.colour = "#ff0000", outlier.size = 3) +
  facet_grid( variable ~ Experiment)
ggsave("../05figures/SoilWaterEDA/DUL_LLmean.pdf", device = "pdf", dpi = 300,  height = 20, width = 15)
