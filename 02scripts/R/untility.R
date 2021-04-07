
library(autoapsimx)
library(data.table)
library(ggplot2)
library(readxl)
source("./R/functions/functions.R")
dt <- read_Sims("c:/Users/cflfcl/Dropbox/Data/APSIM_Sim.xlsx", source = "biomass")
ggplot(dt, aes(Clock.Today, Height, color = Experiment)) +
  geom_point() +
  facet_wrap(~ SowingDate + Experiment)
dt[, max(Height, na.rm = TRUE), by = .(Experiment, SowingDate)]





df <- data.frame(x =  c(0, .15 ,0.75 ,0.9,1),
           y = c(0.4,0.4,0.75,1, 1))

library(ggplot2)
ggplot(df, aes(x, y)) +
   geom_smooth() +
  xlab(expression("T/T_D")) +
  scale_y_continuous(name = "Relative shoot RUE", limits = c(0,1.2), 
                     expand = c(0,0.01), breaks = seq(0, 1, 0.2))+ 
  theme_classic()



# text mining -------------------------------------------------------------

library(pdftools)
physi_path <- list.files("c:/Users/cflfcl/Dropbox/1. master_background_reading/physiology/", 
                         pattern = ".pdf", full.names = TRUE,recursive = TRUE)
dt <- data.frame(path = physi_path)
dt$text <- lapply(dt$path, pdftools::pdf_text)

dt$detect_flower <- lapply(dt$text, function(x){
  unique(grep("flower", x = x, ignore.case = TRUE))
  
})

unlist(dt$detect_flower )
View(dt)
filter <- unlist(lapply(dt$detect_flower, function(x) length(x) == 0))
dt_sub <- dt[!filter, ]
View(dt_sub)

basename(dt_sub$path)
