
# load pkgs ---------------------------------------------------------------


source("02scripts/R/packages.R")
source("02scripts/R/functions.R")

# read prediction data ---------------------------------------------------------------


dbs = list.files("03processed-data/apsimxLucerne/", "*.db$", full.names = TRUE)
dt =  read_dbtab(dbs, table = "Report")
dt[, (c("CheckpointID", "Zone")):= NULL]
dt

pred_SWC = dt[, .(Date, Experiment, SowingDate, PSWC)]

# read observation data ---------------------------------------------------

obs_SWC = readd(SWC_mean)


# SWC  --------------------------------------------------------------------
Sites <- c("AshleyDene", "Iversen12")

sds = unique(obs_SWC$SowingDate)
for(i in Sites){
  for (j in sds){
    pred_1 = pred_SWC[Experiment == i & SowingDate == j]
    obs_1 = obs_SWC[Experiment == i & SowingDate == j]
    pred_obs = merge.data.table(pred_1, obs_1, by.x = c("Date", "Experiment", "SowingDate"),
                                by.y = c("Clock.Today","Experiment", "SowingDate"), all.x = TRUE)
    palette = rep("grey", times = 2)
    palette_named = setNames(palette,  c("Predict SWC", "Observed SWC"))
    palette_named[2] = "red"
    point_size = 2
    pred_obs%>% 
      ggplot(aes(Date)) +
      geom_line(aes(y = PSWC, col = "Predict SWC"))+
      geom_point(aes(y = SWC, col = "Observed SWC"), size = point_size) +
      ggtitle(paste0(unique(pred_obs$Experiment), unique(pred_obs$SowingDate))) +
      scale_x_date(date_labels = "%Y %b", date_breaks = "4 weeks") +
      scale_color_manual(name = "", values = palette_named) +
      theme_water() +
      theme(legend.position = "top",
            axis.text.x = element_text(angle = 30, hjust = 1))
    ggsave(paste0("C:/Data/Master/05figures/kl_LayerByLayerCalibrationEDA/BestfitLayerkl", i, j, "SWC.png"), 
           dpi = 300, height = 7, width = 10)
  }
}


# SW ----------------------------------------------------------------------
dt_sw = readd(SW_mean)
value_vars = readd(value_vars)
for(i in Sites){
  for(j in sds){
    OBS = dt_sw[Experiment == i & SowingDate == j]
    pred = dt[Experiment == i & SowingDate == j]

    pred_SW = data.table::melt(pred,
                               value.name = "pred_VWC",
                               measure.vars = value_vars,
                               variable.name = "Depth",
                               variable.factor = FALSE)
    long = data.table::melt(OBS,
                            value.name = "obs_VWC",
                            measure.vars =value_vars,
                            variable.name = "Depth",
                            variable.factor = FALSE)
    pred_obs = merge.data.table(pred_SW,
                                long, 
                                by.x = c("Date", "Depth"), 
                                by.y = c("Clock.Today", "Depth"),
                                all.x = TRUE)[, Depth := forcats::fct_relevel(as.factor(Depth),                                                                                   paste0("SW(",1:22,")"))]
    palette = rep("grey", times = 2)
    palette_named = setNames(palette,  c("pred_VWC", "obs_VWC"))
    palette_named[2] = "red"
    p1 = pred_obs %>% 
      ggplot(aes(Date)) +
      geom_line(aes(y = pred_VWC, col = "pred_VWC"))+
      geom_point(aes(y = obs_VWC, col = "obs_VWC"), size = 2) +
      facet_grid( Depth ~ .)  +
      ggtitle(paste0(unique(pred_obs$Experiment), unique(pred_obs$SowingDate))) +
      scale_x_date(date_labels = "%Y %b", date_breaks = "4 weeks") +
      scale_color_manual(name = "", values = palette_named) +
      theme_water() +
      theme(legend.position = "top",
            axis.text.x = element_text(angle = 30, hjust = 1))
    
    ggsave(paste0("C:/Data/Master/05figures/kl_LayerByLayerCalibrationEDA/BestfitLayerkl", 
                  i, j, ".png"), p1, dpi = 300, height = 14, width = 8)
    
  }
}

