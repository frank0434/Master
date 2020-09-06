library(sf)
library(raster)
library(dplyr)
library(spData)
library(spDataLarge) # installed from source on github
library(tmap)    # for static and interactive maps
library(leaflet) # for interactive maps
library(ggplot2)
library(magrittr)



df = read.csv("./04manuscript/refData/Latlong.csv", header = TRUE, stringsAsFactors = FALSE)
#https://www.earthdatascience.org/courses/earth-analytics/get-data-using-apis/leaflet-r/
leaflet() %>%
  addTiles() %>%  # use the default base map which is OpenStreetMap tiles
  addMarkers(lng=172.348, lat=-43.646,
             popup="Ashley Dene")

locationMap = leaflet(df) %>%
  addTiles() %>%  # use the default base map which is OpenStreetMap tiles
  addMarkers(lng=~lon, lat=~lat,
             popup=~Site)

mapview::mapshot(locationMap, file = "04manuscript/locationmap.png",
                 vwidth = 900, vheight = 500)



# met file summary --------------------------------------------------------
source("./02scripts/R/packages.R")
path = "./03processed-data/Richard.sqlite3"

AD = read_dbtab(path, "met_AshleyDene")

I12 = read_dbtab(path = path, "met_Iversen12")
AD[, Clock.Today := as.Date(day, origin = paste0(year,"-01-01"))]
AD$Clock.Today %>% range()
I12 = I12[, Clock.Today := as.Date(day, origin = paste0(year,"-01-01"))
          ][Clock.Today %between% range(AD$Clock.Today)]
AD[, seasons := ifelse(Clock.Today >= "2010-06-02" & Clock.Today <= "2011-06-01",
                       "2010/11", 
                       ifelse(Clock.Today >= "2011-06-02" & Clock.Today <= "2012-06-01",
                              "2011/12", "2012"))]
I12[, seasons := ifelse(Clock.Today >= "2010-06-02" & Clock.Today <= "2011-06-01",
                       "2010/11", 
                       ifelse(Clock.Today >= "2011-06-02" & Clock.Today <= "2012-06-01",
                              "2011/12", "2012"))]
AD[, .(AnnualRain = sum(rain, na.rm = TRUE)), by = .(seasons)]
I12[, .(AnnualRain = sum(rain, na.rm = TRUE)), by = .(seasons)]

# PET ---------------------------------------------------------------------

read_excel("./04manuscript/refData/wgenf.xlsx")

