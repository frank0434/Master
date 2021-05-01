

library("shiny")
library("dplyr")
library("ggplot2")
library("leaflet")
library("raster")
library("ggvis")
library("maptools")
library("maps")
library("sp")
library("gplots")
library("htmltools")
library("readr")
library("DT")
library("pool")
library("shinyjs")


source("~/powerplant/creds.R")
pool <- dbPool(
  RPostgreSQL::PostgreSQL(), 
  dbname = P009_LucerneNZ$dbname,
  host = P009_LucerneNZ$host,
  user = P009_LucerneNZ$username,
  password = P009_LucerneNZ$password)
input <- list()
input$mainvar <- "Biomass"
input$gcm <- "1"
input$gcm2 <- "1"
input$rcp <- "1"
input$scn <- "1"
input$ra_match_scales <- T
input$ra_colours <- "sequential"
input$stats = 5
mainvar <- "Biomass"
factor_df <- pool %>% 
  tbl("Factor") %>% 
  collect()
factors <- unique(factor_df$variable)
pixel_df <- pool %>% 
  tbl("Pixel") %>% 
  collect()
ref_df <- pool %>%
  tbl("Simulation") %>%
  filter(gcm_id %in% !!input$gcm) %>%
  filter(rcp_id %in% !!input$rcp) %>%
  filter(time_slice_id %in% !!input$scn) %>%
  filter(SoilStamp %in% "SandLoam") %>%
  filter(DefoliationCycle %in% "Long") %>%
  filter(DormancyRating %in% "FD5") %>%
  filter(IrrigationTreatment %in% "Rainfed") %>%
  # filter(Species %in% "Maize silage") %>%
  dplyr::select(simulation_id,pixel_id,one_of(!!input$mainvar)) %>%
  # dplyr::select(simulation_id,pixel_id,one_of(!!input$mainvar,!!factors)) %>%
  collect() %>%
  left_join(pixel_df)
basemap_ra_ref = createMainMap(pixel_df)

source("ShinyApp/app/functions.R")

statSelection = 5
r = ref_df %>%
  dplyr::select(Lat,Lon, mainvar) %>%
  group_by(Lat, Lon) %>%
  summarise(mean = mean(get(mainvar))) %>%
  dplyr::select(Lat, Lon, thisVar = mean)
rasterDF_Alt  = r
pal <-  map_colour_palette(r, rasterDF_Alt, input$ra_match_scales, input$ra_colours)
if(input$ra_match_scales)  valRasters <- c(r$thisVar, rasterDF_Alt$thisVar)
leaflet("basemap_ra_ref") %>%
  addTiles() %>%
  fitBounds(min(pixel_df$Lon), min(pixel_df$Lat), max(pixel_df$Lon), max(pixel_df$Lat)) %>% 
  addRectangles(r$Lon+halfPixelDeg, r$Lat+halfPixelDeg,
                r$Lon-halfPixelDeg, r$Lat-halfPixelDeg,
                color = pal(r$thisVar), fillOpacity = 1, weight = 0) %>%
  addLegend(pal = pal, values = legendValues, 
            title = units)

leaflet(rasterDF_Alt)
halfPixelDeg  = 0.025


leaflet("basemap_ra_ref") %>% 
  clearImages() %>% 
  clearControls() %>% 
  clearMarkers() %>% 
  clearGroup(group=c("Rasters","boundaries"))
opacity = 0.5
boundaries = "none"
units = "kg DM/ha"
geoJsonList = NULL
pal = pal
legendValues = r$thisVar
leaflet("basemap_ra_ref") %>%
  addRectangles(r$Lon+halfPixelDeg, r$Lat+halfPixelDeg,
                r$Lon-halfPixelDeg, r$Lat-halfPixelDeg,
                color = pal(r$thisVar), fillOpacity = 1, weight = 0,
                group = "Rasters") %>%
  # addMarkers(r$Lon,r$Lat, group="Data Points") %>%
  addLegend(pal = pal, values = legendValues, 
            title = units)
