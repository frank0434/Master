
source("02scripts/R/packages.R")
source("02scripts/R/functions.R")

path = here::here("03processed-data/Richard.sqlite3")
water = read_dbtab(path,  "SoilWater")
water = rename_cols(DT = water[, `SW(2)`:=NULL])
id_vars <- colnames(water)[!colnames(water) %in% grep("SW\\(\\d.+", colnames(water), value = TRUE)]
value_vars <- colnames(water)[!colnames(water) %in% id_vars]
id_vars = c("Experiment","Clock.Today", "Season","SowingDate", "DAS")
SW_mean <- water[, lapply(.SD, mean, na.rm = TRUE), by = id_vars, .SDcols = value_vars]


# Subset season 1 ---------------------------------------------------------

season1 = melt(SW_mean[Season == "2010/11"], id.vars = id_vars,
               variable.name = "Depth", value.name = "SW", 
               variable.factor = FALSE)
season1[, Depth := as.integer(gsub("\\D", "", Depth))]
season1[, SW := mean(SW,na.rm = TRUE), by = .(Experiment, Clock.Today, Season, SowingDate, DAS, Depth) ][]


# load initial soil conditions from cache ---------------------------------

loadd(SW_DUL_LL)
dul = SW_DUL_LL[,.(Experiment, SowingDate,Depth, DUL, LL, PAWC)]
season1 = merge(season1, dul, by = c("Experiment","SowingDate","Depth"),
                all.x = TRUE, suffixes = c("", "_started"))

# Update the subset to have a relative SW ---------------------------------

season1[, ':='(relativeSW = SW/100/DUL,
               Depth = as.factor(Depth))][]
# Get other data  ---------------------------------------------------------

biomass = read_dbtab(here::here("03processed-data/Richard.sqlite3"), "biomass")
met = read_dbtab(here::here("03processed-data/Richard.sqlite3"), "met_Iversen12")


# mcp I12 --------------------------------------------------------------------

# Define the model 
model = list(
  relativeSW ~ 1 + sigma(1),  # plateau (int_1)
  ~ 0 + DAS ,       # joined slope (time_2) at cp_1, could be a exp decay function.
  ~ 0  
)
# Define the prior
prior = list(
  # Intercept should be between 0.5 and 1; less than 1
  ## Evidence in the hist above
  int_1 = "dnorm(0.5, 1) T(, 1)" 
)


# max layer with more than 5% std ---------------------------------------------------------------

maxDepthS1 = I12SD[, .(sd(relativeSW)), by = .(Depth)
                   ][V1 > 0.05][, .N]
for(site in c("AshleyDene", "Iversen12")){
  for(SD in paste0("SD", 1:5)){
    

  I12SD = season1[Experiment == site & SowingDate == SD]
  ldpethi12=lapply(1:maxDepthS1, function(n){
    # Cut the data before the rain fall
    dt = I12SD[Depth == n & DAS < 150]
    # Fit it. 
    fit = mcp(model, data = dt, cores = 3, prior = prior)
    # Extract the cp one 
    cp_1_est = as.data.table(summary(fit))
    # int_range = cp_1_est[name == "int_1"]
    # if((int_range$upper - int_range$lower) > 0.05){
    setkey(dt, DAS)
    
    close_das = dt[dt[J(cp_1_est$mean[1]), roll = 'nearest', which = TRUE]]$DAS
    P = plot(fit) +
      geom_vline(xintercept = c(cp_1_est$mean[1],close_das), 
                 color =  c("red","black")) +
      ggtitle(paste0("Layer ",n))+
      theme_water()
    if(!dir.exists(here::here("05figures/RFVEDA"))){
      dir.create(here::here("05figures/RFVEDA"))
      ggsave(here::here("05figures/RFVEDA", paste0(site, SD, "Layer_", n,'.png')),
             dpi = 300, height = 8, width = 8)
    } else {
      ggsave(here::here("05figures/RFVEDA", paste0(site, SD, "Layer_", n,'.png')),
             dpi = 300, height = 8, width = 8)
    }
  
    l = vector("list", 2)
    l[[1]] = fit
    l[[2]] = P
    
    l
    # } else(
    # cat("Layer", n, "has less than 0.05 changes. Ignored. \r\n")
    # )
    })
  I12SD_fit = lapply(ldpethi12, function(x){
    fit = summary(x[[1]])
    fit
  })



    
    DT_fit = rbindlist(I12SD_fit, use.names = TRUE, idcol = "Depth")
    DT_fit[, variance := upper - lower]
    I12SD_RFV = DT_fit[name == "cp_1" & Depth <= maxDepthS1] %>% 
      ggplot(aes( mean, Depth)) +
      geom_point(size = 5)  +
      # coord_flip() +
      scale_y_reverse() +
      theme_water() +
      labs( x = "DAS")
    
    
    cuts = biomass[Experiment == site & SowingDate == SD, 
                   .(Experiment, Clock.Today, Season, Rotation.No.,SowingDate, DAS )]
    
    cuts_SD = unique(cuts)[, .SD[.N], by = .(Rotation.No., Season)]
    I12SD_RFV_CUT = I12SD_RFV +
      geom_vline(data = cuts_SD[Season == "2010/11" ], aes(xintercept = DAS), color = "red")  +
      annotate("text", x = 75 + 1, y = 25 , label = "Red Lines were cutting dates", size = 10) 
    
    met_SD = met[year >=2010 & year < 2013
                 ][, Clock.Today := as.Date(day, origin = paste0(year, "-01-01"))
                   ][Clock.Today %between% range(I12SD$Clock.Today)]
    rain_SD = met_SD[, DAS:= seq(3, nrow(met_SD) + 2, 1)][,.(DAS, rain)]
    I12SD_RFV_CUT+
      geom_col(data = rain_SD, aes(x = DAS, y = rain, fill = "Rainfall"), alpha= 0.5)+
      scale_fill_manual(name = "", values = (Rainfall = "blue"), ) +
      ggtitle(paste0(unique(cuts_SD$Experiment), " ", unique(cuts_SD$SowingDate)))+
      theme(panel.grid.major.y = element_line(colour = "grey50"),
            panel.grid.minor.y = element_line(colour = "grey80"))
    
    ggsave(here::here("05figures/RFVEDA", paste0(site, SD,'.png')),
           dpi = 300, height = 8, width = 8)
  }
  
}

