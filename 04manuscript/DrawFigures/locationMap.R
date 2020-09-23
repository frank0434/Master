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



# PET ---------------------------------------------------------------------

read_excel("./04manuscript/refData/wgenf.xlsx")

