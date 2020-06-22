

library(drake)



# stats fail --------------------------------------------------------------

# x fail stats
# Error: target stats failed.
# diagnose(stats)error$message:
#   Invalid argument type: 'sim' & 'obs' have to be of class: c('integer', 'numeric', 'ts', 'zoo')
# diagnose(stats)error$calls:
#   1. \-autoapsimx::sims_stats(pred_obs = pred_swc)
# 2.   +-...[]
# 3.   \-data.table:::`[.data.table`(...)
# 4.     \-base::eval(jsub, SDenv, parent.frame())
# 5.       \-base::eval(jsub, SDenv, parent.frame())
# 6.         \-base::lapply(...)
# 7.           \-autoapsimx:::FUN(X[[i]], ...)
# 8.             +-hydroGOF::gof(x$PSWC, x$SWC)
# 9.             \-hydroGOF::gof.default(x$PSWC, x$SWC)
# 10.               +-hydroGOF::me(sim, obs, na.rm = na.rm)
# 11.               \-hydroGOF::me.default(sim, obs, na.rm = na.rm)
# 12.                 \-base::stop("Invalid argument type: 'sim' & 'obs' have to be of class: c('integer', 'numeric', 'ts', 'zoo')")


loadd()
ls()
pred_swc
# The manipulate fun didn't join the two DT correctly. 
# Because column SWC has been filtered out 
obs_sd
pred_swc

DT_stats_sub_SW = readd(DT_stats_sub_SW)
DT_stats_sub_SW[, unlist(data, recursive = FALSE), 
                by = stats_key_SW_extra]


AD_SD2 = readd(Site_SD_SW_AshleyDene_SD2)
AD_SD2$Depth %>% unique()
AD_SD2$KLR %>% unique()
AD_SD2$SKL %>% unique()
palette = rep("grey", times = 2)

palette_named = setNames(palette,  c("Predict VWC", "Observed VWC"))
palette_named[2] = "red"
point_size = 2
AD_SD2[Depth == "SW(20)"] %>% 
  ggplot(aes(Date)) +
  geom_point(aes(y = pred_VWC, color = "Predict VWC"), size = point_size) +
  geom_point(aes(y = ob_VWC, color = "Observed VWC"), size = point_size) +
  facet_grid( KLR_RFV_SKL~ .) +
  labs(
    # title = paste0("Surface kl = ", unique(AD_SD2$SKL)),
       y = "VWC") +
  theme_water() +
  scale_x_date(date_labels = "%Y %b") +
  scale_color_manual(name = "", values = palette_named) +
  theme(legend.position = "top", 
        axis.text.x = element_text(angle = 30, hjust = 1)) +
  geom_text(aes(x = as.Date("2011-07-01"), y = median(AD_SD2$pred_VWC),
                label = paste0("NSE = ", NSE,
                               "\r\nR.square = ", R2,
                               "\r\nRMSE = ", RMSE)),
            vjust = "inward", hjust = "inward",
            inherit.aes = FALSE)

# join


# i Consider drake::r_make() to improve robustness.
# > target plot_SW_pred_obs_pred_SW_Site_SD_Iversen12_SD4_long_obs_SW_Iversen12_SD4
# > target plot_Site_SD_AshleyDene_SD1
# x fail plot_Site_SD_AshleyDene_SD1
# Error: target plot_Site_SD_AshleyDene_SD1 failed.
# diagnose(plot_Site_SD_AshleyDene_SD1)error$message:
#   At least one layer must contain all faceting variables: `Depth`.
# * Plot is missing `Depth`
# * Layer 1 is missing `Depth`
# * Layer 2 is missing `Depth`
# * Layer 3 is missing `Depth`
# diagnose(plot_Site_SD_AshleyDene_SD1)error$calls:
#   1. \-autoapsimx::plot_params(DT = Site_SD_AshleyDene_SD1, file_out("C:/Data/Master/05figures/klEDA/plot_Site_SD_AshleyDene_SD1"))
# 2.   \-ggplot2::ggsave(...)
# 3.     +-grid::grid.draw(plot)
# 4.     \-ggplot2:::grid.draw.ggplot(plot)
# 5.       +-base::print(x)
# 6.       \-ggplot2:::print.ggplot(x)
# 7.         +-ggplot2::ggplot_build(x)
# 8.         \-ggplot2:::ggplot_build.ggplot(x)
# 9.           \-layout$setup(data, plot$data, plot$plot_env)
# 10.             \-ggplot2:::f(..., self = self)
# 11.               \-self$facet$compute_layout(data, self$facet_params)
# 12.                 \-ggplot2:::f(...)
# 13.                   \-ggplot2::com
# In addition: There were 50 or more warnings (use warnings() to see the first 50)

dt = readd(pred_obs_pred_SW_Site_SD_Iversen12_SD4_long_obs_SW_Iversen12_SD4)
dt %>% 
  plot_params("./05figures/TEST.PNG", 
              col_pred = "pred_VWC", 
              col_obs = "obs_VWC", 
              Depth = "Depth", width = 8, height = 16)
dt = readd(Site_SD_AshleyDene_SD1)
dt %>% 
  plot_params("./05figures/TEST"              )


library(drake)
library(autoapsimx)
db <- "./03processed-data/apsimxFilesLayers/SKL_0.01RFV_15AshleyDeneSD10L10kl0.005.db"
# x fail l_stats_layerKL
# Error: target l_stats_layerKL failed.
# diagnose(l_stats_layerKL)error$message:
#   missing value where TRUE/FALSE needed
# diagnose(l_stats_layerKL)error$calls:
#   1. \-autoapsimx::sims_stats_multi(...)
# 2.   \-autoapsimx::sims_stats(...)
# 3.     +-...[]
# 4.     \-data.table:::`[.data.table`(...)
# 5.       \-base::eval(jsub, SDenv, parent.frame())
# 6.         \-base::eval(jsub, SDenv, parent.frame())
# 7.           \-base::lapply(...)
# 8.             \-autoapsimx:::FUN(X[[i]], ...)
# 9.               +-hydroGOF::gof(x[[col_pred]], x[[col_obs]])
# 10.               \-hydroGOF::gof.default(x[[col_pred]], x[[col_obs]])
# 11.                 +-hydroGOF::rsr(sim, obs, na.rm = na.rm, ...)
# 12.                 \-hydroGOF::rsr.default(sim, obs, na.rm = na.rm, ...)
# In addition: There were 50 or more warnings (use warnings() to see the first 50)
pred_I12SD1 <- read_dbtab(db, table = "Report")
layerNo. <- regmatches(basename(db), regexpr("L\\d{1,2}", basename(db)))
layer <- gsub("(L)(\\d{1,2})", "SW\\\\(\\2\\\\)", layerNo.)
depth_int <- as.integer(gsub("L", "", layerNo.))
colsofInteresetd <- grep(pattern = layer, colnames(pred_I12SD1), value = TRUE)
keys <- grep("SW", colnames(pred_I12SD1), invert = TRUE, value = TRUE)
cols <- c(keys, colsofInteresetd)
pred <- pred_I12SD1[,..cols
                    ][, Depth := depth_int]
data.table::setnames(pred, colsofInteresetd, "pred_VWC")
obs_I12SD1 <- readd(SW_mean)
keys_obs <- grep("SW", colnames(obs_I12SD1), invert = TRUE, value = TRUE)
cols <- c(keys_obs, colsofInteresetd)
site = extract_trts(db)[1]
sd = extract_trts(db)[2]
obs <- obs_I12SD1[,..cols
                  ][Experiment == site&
                      SowingDate == sd
                    ][, Depth := depth_int]
data.table::setnames(obs, colsofInteresetd, "ob_VWC")

pred_obs <- data.table::merge.data.table(pred, obs,
                                         by.x = c("Date", "Depth"),
                                         by.y = c("Clock.Today", "Depth"))
stats <- sims_stats(pred_obs,
                    keys = c("Experiment", "SowingDate", "Depth"),
                    col_pred = "pred_VWC",
                    col_obs = "ob_VWC")
stats$stats
layerNo. <- regmatches(basename(i), regexpr("L\\d{1,2}", basename(i)))
layer <- gsub("(L)(\\d{1,2})", "SW\\\\(\\2\\\\)", layerNo.)
depth_int <- as.integer(gsub("L", "", layerNo.))
colsofInteresetd <- grep(pattern = layer, colnames(dt), value = TRUE)
obs_sd <- DT_observation[Experiment == "AshleyDene" &
                 SowingDate == "SD10"]
keys_obs <- grep("SW", colnames(obs_sd), invert = TRUE, value = TRUE)
cols <- c(keys_obs, colsofInteresetd)
obs <- obs_sd[,..cols
              ][, Depth := depth_int]
data.table::setnames(obs, colsofInteresetd, "ob_VWC")

pred_obs <- data.table::merge.data.table(pred, obs,
                                         by.x = c("Date", "Depth"),
                                         by.y = c("Clock.Today", "Depth"))

stats <- sims_stats(pred_obs = pred_obs,
                    keys = keys,
                    col_pred = "pred_VWC",
                    col_obs = "ob_VWC")

dt = read_dbtab(db, "Report")
treatmentNamse = extract_trts(filename = db)
treatmentNames <- extract_trts(filename =db)
site <- treatmentNames[1]
sd <- treatmentNames[2]
DT = readd(SW_mean)

obs_sd <- DT[Experiment == site & SowingDate == sd]
layerNo. <- regmatches(basename(i), regexpr("L\\d{1,2}", basename(i)))
layer <- gsub("(L)(\\d{1,2})", "SW\\\\(\\2\\\\)", layerNo.)
depth_int <- as.integer(gsub("L", "", layerNo.))
colsofInteresetd <- grep(pattern = layer, colnames(dt), value = TRUE)
keys <- grep("SW", colnames(dt), invert = TRUE, value = TRUE)
cols <- c(keys, colsofInteresetd)
pred <- dt[,..cols
           ][, Depth := depth_int]
data.table::setnames(pred, colsofInteresetd, "pred_VWC")

keys_obs <- grep("SW", colnames(DT), invert = TRUE, value = TRUE)
cols <- c(keys_obs, colsofInteresetd)
obs <- obs_sd[,..cols
              ][, Depth := depth_int]
data.table::setnames(obs, colsofInteresetd, "ob_VWC")

pred_obs <- data.table::merge.data.table(pred, obs,
                                         by.x = c("Date", "Depth"),
                                         by.y = c("Clock.Today", "Depth"))
stats <- sims_stats(pred_obs = pred_obs,
                    keys = keys,
                    col_pred = "pred_VWC",
                    col_obs = "ob_VWC")
is.data.table(pred_obs)
col_pred %in% colnames(pred_obs)
col_obs %in% colnames(pred_obs)
setkeyv(pred_obs, keys)
nested <- pred_obs[, list(data = list(.SD)), by = key(pred_obs)]
nested <- nested[, stats := lapply(data, function(x){
  # Calculate the stats via goodness of fit
  m <- hydroGOF::gof(x[[col_pred]], x[[col_obs]])
  # Convert the matrix into a data.table with colnames
  m <- m %>%
    as.data.table(keep.rownames = T) %>%
    transpose(make.names = 'rn')
})]
nested$stats
