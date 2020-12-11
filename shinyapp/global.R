library("shiny")
library("dplyr")
library(data.table)
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

# meta <- data.table::fread(here::here("Data/ProcessedData/best_fit.csv")) 
# meta <- meta[, filenames:= paste0(here::here(), "/Data/ProcessedData/apsimxFiles/", (basename(filenames)))]
# meta[Experiment =="AshleyDene" & SowingDate == "SD1", filenames := "C:/Data/Master/Data/ApsimxFiles/20200517BaseSlurp.db"]
meta <- data.table::data.table(filenames = list.files(here::here("Data/ProcessedData/apsimxFiles2020.12.11.16.03.42/"),
                                                      pattern = "*.db$",
                                                      full.names = TRUE))
meta[, basename := gsub(".db","", basename(filenames))
     ][, (c("Experiment", "SowingDate")) := data.table::tstrsplit(basename, split = "_")]
# meta
experiments <- unique(meta$Experiment)
SowingDate <- unique(meta$SowingDate)
DUL_LL_range <- fread(here::here("Data/dul_ll_stats.csv")
                      )[Depth == 1,':='(DUL = SW.mean.DUL * 200,
                                        SE = SW.sd.DUL * 200 / SW.n.DUL)
                        ][Depth != 1, ':='(DUL = SW.mean.DUL * 100,
                                           SE = SW.sd.DUL * 100 / SW.n.DUL)]
# factor_inputs <- c("SKL","KLR","RFV", "SimulationID")

#palette(c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3",
#  "#FF7F00", "#FFFF33", "#A65628", "#F781BF", "#999999"))

