library("shiny")
library("dplyr")
library("ggplot2")
library("ggvis")
library("htmltools")
library("readr")
library("DT")
library("pool")
library("shinyjs")
library("shinyWidgets")

## DEVelopment switch
DEV <- TRUE
options(shiny.sanitize.errors = !DEV, scipen = 999)

poolConnection <- NULL

meta <- data.table::fread(here::here("Data/ProcessedData/best_fit.csv")) 
meta <- meta[, filenames:= paste0(here::here(), "/Data/ProcessedData/apsimxFiles/", (basename(filenames)))]
experiments <- unique(meta$Experiment)
SowingDate <- sort(unique(meta$SowingDate))
# factor_inputs <- c("SKL","KLR","RFV", "SimulationID")

#palette(c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3",
#  "#FF7F00", "#FFFF33", "#A65628", "#F781BF", "#999999"))

