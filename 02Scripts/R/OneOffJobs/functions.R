##############################
# Functions for Modifying UI #
##############################

oldDatabase <- F

build_factor_dropdowns <- function(factor_df,type,no, pool = NULL) {

  # it creates a list of dropdown control in html form
  # that can be accessed by - input$factor_[factorName]_[type]
  #   eg input$factor_SoilStamp_ref
  #   eg input$factor_Water_alt
  
  dropdown_list <- list()
  inputname_list <- list()
  factors <- unique(factor_df$variable)
  factors <- factors[factors != "year"]
  j <- 0
  if(!("RCP" %in% factors)){
  	oldDatabase <<- T
  	controls <- c(RCP="RCP",GCM="GCM",TimeSlice="TimeSlice")
  	
  	for(k in 1:length(controls)){
	  	factor <- names(controls)[k]
	  	factor_choices_df <- pool %>%
	  		tbl(controls[k]) %>%
	  		dplyr::select(c(1,"name")) %>%
	  		collect()
	  	factor_choices <- factor_choices_df[,1][[1]]
	  	names(factor_choices) <- factor_choices_df[,2][[1]]
	  	cmb <- selectInput(
	  		inputId = paste0("factor_", factor, "_", type),
	  		label = paste0(factor," #",no),
	  		choices = c(factor_choices, `All`="all"),
	  		selected = 1)
	  	dropdown_list[[k]] <- cmb
	  	inputname_list[[k]] <- paste0("factor_", factor, "_", type)
	  	names(inputname_list[[k]]) <- factor
	  	j <- k
  	}
  	
  }else{
  	oldDatabase <<- F
  }
  
  for(i in seq_along(factors)) {
    factor <- factors[i]
    factor_choices <- factor_df[factor_df$variable ==factor,]$value
    cmb <- selectInput(
      inputId = paste0("factor_", factor, "_", type),
      label = paste0(factor," #",no),
      choices = c(factor_choices, `All`="all"),
      selected = 1)#factor_choices[1])
    dropdown_list[[i+j]] <- cmb
    inputname_list[[i+j]] <- paste0("factor_", factor, "_", type)
    names(inputname_list[[i+j]]) <- factor
  }
  if (type == "ref") {
    inputname_list_ref <<- inputname_list
  } else {
    inputname_list_alt <<- inputname_list
  }
  return(dropdown_list)
}


#removes options that are not available for a given scenario
#if an option that was selected is no longer available then the first
#option in the new list is the one that is used.
limit_factor_dropdowns <- function(input, 
																	 factor_names, 
																	 scenario_df, 
																	 session){
	
	if(!is.null(input[[factor_names[[1]]]])){
		limited_scenario_df <- scenario_df
		for(i in 1:(length(factor_names)-1)){
			
			limited_scenario_df <- limited_scenario_df[limited_scenario_df[[names(factor_names[[i]])]] == input[[factor_names[[i]]]],]
			
			current_input <- input[[factor_names[[i + 1]]]]
			available_inputs <- unique(limited_scenario_df[[names(factor_names[[i+1]])]])
			
			if(current_input %in% available_inputs){
				updateSelectInput(session = session,
													inputId = factor_names[[i+1]][[1]],
													choices = available_inputs,
													selected = current_input)
				
			}else{
				updateSelectInput(session = session,
													inputId = factor_names[[i+1]][[1]],
													choices = available_inputs,
													selected = available_inputs[1])
				#if an input needs to be updated then update it and leave this
				#function. The update will trigger the xxxInputChanged function
				#in server.r which will re-call this function.
				return()
			}
		}
	}
}

######################
# Database Functions #
######################

#close the DB when the app stops/crashes
onStop(function() {
	print("Closing connection to DB")
	if(!is.null(poolConnection)){
		poolClose(poolConnection)
	}
})


## function for querying simulation table
simulation_query <- function(pool,
                             variable,
                             pixel_df,
                             factor_inputs,
														 discreteValues = F) {
	
	if(discreteValues & variable %in% names(factor_inputs)){
		factor_inputs[[variable]] <- "all"
	}
	
  shinyjs::show(id = "loading-page")
	print("Running simulation Query")
	sql <- ""
	simulation_df <- NULL
	tryCatch({
		if(!oldDatabase){
			sql <- paste("select scenario_id",
									 'from "Scenario" where 1=1')
			limitSql <- "and \"%s\" = '%s'"
			for(i in 1:length(factor_inputs)){
				sql <- paste(sql, sprintf(limitSql, 
																	names(factor_inputs)[i],
																	factor_inputs[i]))
			}
			cat(sql)
			cat('\n')
			scenario_id <- pool %>%
				dbGetQuery(sql)
			sql <- paste0("select simulation_id, pixel_id, ", 
									 '"',variable,'", year',
									 ' from "Simulation" where scenario_id = ', 
									 "'",scenario_id,"'")
			cat(sql)
			simulation_df <- pool %>%
				dbGetQuery(sql) %>%
				collect()
			simulation_df  <- left_join(simulation_df,pixel_df)
		}else{
			
				# sql <- paste0("select simulation_id, pixel_id, ", 
				# 							'"',variable, '", year',
				# 						 ' from "Simulation" where 1=1')
				sql <- paste0('select * from "Simulation" where 1=1')
				limitSql <- "and \"%s\" = '%s'"
				
				if(factor_inputs[1] != "all"){
					sql <- paste(sql, sprintf(limitSql, 
																		"rcp_id",
																		factor_inputs[1]))
				}
				if(factor_inputs[2] != "all"){
					sql <- paste(sql, sprintf(limitSql, 
																		"gcm_id",
																		factor_inputs[2]))
				}
				if(factor_inputs[3] != "all"){
					sql <- paste(sql, sprintf(limitSql, 
																		"time_slice_id",
																		factor_inputs[3]))
				}
				
				for(i in 4:length(factor_inputs)){
					if(factor_inputs[i] != "all"){
						sql <- paste(sql, sprintf(limitSql, 
																			names(factor_inputs)[i],
																			factor_inputs[i]))
					}
				}
				cat(sql)
				simulation_df <- pool %>%
					dbGetQuery(sql) %>%
					collect()
				simulation_df <- left_join(simulation_df,pixel_df)
				simulation_df <- rowwise(simulation_df)
				if(!discreteValues){
					#simulation_df <- dplyr::mutate(simulation_df, !!variable :=as.numeric(get(variable)))
				}


				for(i in 1:ncol(simulation_df)){
					simulation_df[[i]] <- ifelse(is.na(as.numeric(simulation_df[[i]])),
																			 simulation_df[[i]],
																			 as.numeric(simulation_df[[i]]))
				}

				}
	  },

	error = function(e) NULL,
	finally={
		hide(id = "loading-page")
	})
	
  #validate(need(nrow(df)>0,'Scenario not available. Please select again.'))
  if(is.null(simulation_df) || nrow(simulation_df) == 0){
  	print('Scenario not available. Please select again.')
  	return(NULL)
  }
	# print("before return")
	print(head(simulation_df))
  return(as_tibble(simulation_df))
}

filter_df <- function(input, df) {
  col_name<-quo(!!as.name(names(input)))
  df %>% filter((!!col_name) == !!input)
}

filter_factors <- function(factor_inputs, df){
  ## for loop
  filtered_df <- df
  for (i in seq(factor_inputs)) {
    filtered_df <- filter_df(factor_inputs[i],filtered_df)
  }
  return(filtered_df)
}

###################
# Stats Functions #
###################

# Function to select stat type
statTypeFunc <- function(x, type) {
  switch(type,
         av = mean(x),
         cv = sd(x)/mean(x))
}

# simple cv function
cvFunc <- function(x) {
  cv <- round((sd(x)/mean(x))*100,1)
}


######################
# Plotting Functions #
######################

# Default function: add parameters if necessary to taylor maps later
createMainMap <- function(points) {
  
	leaflet() %>%
		addTiles() %>%
		fitBounds(min(points$Lon), min(points$Lat), max(points$Lon), max(points$Lat)) %>%
		# addPolygons(data=sf2, fill = F ,opacity = 0.7, weight = 2, group = "Catchment Borders") %>%       
		addLayersControl(
			overlayGroups = c("Rasters","Data Points"),
			options = layersControlOptions(collapsed = FALSE)) %>%
		hideGroup("Data Points")
}

# add polygon custom function
addMyPolygon <- function (x, y) {
  leafletProxy(x, data = y) %>%
    addPolygons(data=y, fill = F ,opacity = 0.7, weight = 2, group = "Catchment Borders") %>%       
    addLayersControl(
      overlayGroups = "Kaituna catchment",
      options = layersControlOptions(collapsed = FALSE))
}

# show popup in map
showPopup <- function(lat, lng, text = "Hello World", mapName = "basemap_ra_ref") {
  leafletProxy(mapName) %>% addPopups(lng, lat, text)
}

# returns a vector of colours used for mapping
getGraphColours <- function(paletteName){
  palettes <- list("original" = c("#8B0000","#EE4000", "#FFA500","#008B45"),
                   "grayScale" = c("#B9B9B9", "#000000"),
                   "diverging" = c('#b2182b','#ef8a62','#fddbc7','#d1e5f0','#67a9cf','#2166ac'),
                   "sequential" = c('#ffffb2','#fed976','#feb24c','#fd8d3c','#f03b20','#bd0026'))
  return(palettes[[paletteName]])
  
}

getGeoJSON <- function(pool, tableName = "gisdata"){
  query <- "SELECT row_to_json(fc)
            FROM ( SELECT 'FeatureCollection' As type, array_to_json(array_agg(f)) As features
			      FROM (SELECT 'Feature' As type
			 			, ST_AsGeoJSON(lg.geom)::json As geometry
			 			, row_to_json((SELECT l FROM (SELECT gid, geom) As l
			 			)) As properties
			 			FROM %s As lg) As f )  As fc;"
  query <- sprintf(query, tableName)
  geoJSON <- NULL
  tryCatch({
  	geoJSON <- dbGetQuery(pool, query)
  },
  error = function(e) NULL)
  return(geoJSON)
}

getRegionsAsSPDF <- function(dbCon, tableName = "gisdata"){
	geoJSON <- getGeoJSON(dbCon, tableName)[[1]]
	if(!is.null(geoJSON)){
		regions <- rgdal::readOGR(geoJSON, "OGRGeoJSON", verbose = F)
		return(regions)
	}
}


#Returns a raster of a dataframe
rasterDF <- function(df, mainvar,stat, inputs){
	# if(any(grepl("median", inputs))){
	# 	stat <- 5
	# }
	if(!is.null(df)){
		
		r <- df %>%
			dplyr::select(Lat,Lon, mainvar) %>%
			group_by(Lat, Lon) %>%
			summarise_all(funs(mean,cvFunc,median)) %>%
			dplyr::select(Lat, Lon, thisVar = stat)
		
		#validate(need(nrow(r[!is.na(r$thisVar),])>0,'Scenario not available. Please select again.'))
		
		return(r)
	}
	return(NULL)
}


# Returns the diff between the 2 main rasters on RA tab
rasterDF_Diffcalc <- function(r1, r2, comp){

	df_diff <- 
		merge(r1, r2, by = c("Lat","Lon")) %>% # join base and alt dfs by lat and lon
		rowwise %>%
		mutate(thisVar = ifelse(comp == "abs",
														thisVar.y - thisVar.x, # alt - base
														round(((thisVar.y - thisVar.x) / thisVar.x ) * 100 , 2)) # (base-fut)/base as percent)
		) %>% dplyr::select(Lat, Lon, thisVar) # trim df to a simple lat/long/var  
	
	# validate(need(nrow(df_diff)>0,'Scenario not available. Please select again.'))
	
	return(df_diff)
}

getPixelFromClick <- function(inputClick, proj_df, pixel_df){
	
	lat <-  as.numeric(as.character(inputClick$lat))
	lng <-  as.numeric(as.character(inputClick$lng))
	
	if(is.null(lat)| is.null(lng)) {
		lat <- proj_df$Lat
		lng <- proj_df$Lon
	} else {
		lat <- lat
		lng <- lng
	}
	
	pixel_df$Lat1 <- pixel_df$Lat-halfPixelDeg
	pixel_df$Lat2 <- pixel_df$Lat+halfPixelDeg
	pixel_df$correct_lat <- (lat > pixel_df$Lat1 & lat < pixel_df$Lat2)
	
	pixel_df$Lon1 <- pixel_df$Lon-halfPixelDeg
	pixel_df$Lon2 <- pixel_df$Lon+halfPixelDeg
	pixel_df$correct_lon <- (lng > pixel_df$Lon1 & lng < pixel_df$Lon2)
	
	correct_pixel <- pixel_df[pixel_df$correct_lat & pixel_df$correct_lon,]
	if(nrow(correct_pixel) != 1){
		return(NA)
	}
	
	return(c(correct_pixel$Lat,correct_pixel$Lon))
	
	
}

# Returns a 0.05 deg grid that covers all datapoints  
createGrid <- function(df){
	gridTop <- GridTopology(c(min(df$Lon),min(df$Lat)),
													c(pixelSizeDeg,pixelSizeDeg),
													c(length(seq(min(df$Lon),max(df$Lon), by = pixelSizeDeg))+0,
														length(seq(min(df$Lat),max(df$Lat), by = pixelSizeDeg))+0))
	return(gridTop)
}

createRaster <- function(df){
	if(!is.null(df) && nrow(df) > 0){
		coordinates(df) <- ~ Lon + Lat # Attention to variable names
		
		df <- SpatialPixelsDataFrame(as(df, "SpatialPoints"), data=as.data.frame(df$thisVar), grid = createGrid(df))
		proj4string(df) <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
		r <- raster(df)

		return(r)
	}
	return(NULL)
}

map_colour_palette <- function(dataset1, dataset2 = NULL, match_scales = F, colours = "original"){
	if(match_scales && !is.null(dataset2)){
		pal <- colorNumeric(getGraphColours(colours), 
												c(dataset1$thisVar,
													dataset2$thisVar), na.color = ifelse(F,"#808080","transparent"))
		
		
	}else{
		pal <- colorNumeric(getGraphColours(colours), 
												dataset1$thisVar, na.color = ifelse(F,"#808080","transparent"))
		
		
	}
}

plot_map <- function(mapName, pixelData, legendValues = pixelData$thisVar, 
										 opacity = 0.5, boundaries = "none", units = "",
										 geoJsonList = NULL, pal = pal){
	
	#clean up map for replotting
	leafletProxy(mapName) %>% 
		clearImages() %>% 
		clearControls() %>% 
		clearMarkers() %>% 
		clearGroup(group=c("Rasters","boundaries"))
	
	leafletProxy(mapName) %>%
		addRectangles(pixelData$Lon+halfPixelDeg, pixelData$Lat+halfPixelDeg,
									pixelData$Lon-halfPixelDeg, pixelData$Lat-halfPixelDeg,
									color = pal(pixelData$thisVar), fillOpacity = opacity, weight = 0, group = "Rasters") %>%
		addMarkers(pixelData$Lon,pixelData$Lat, group="Data Points") %>%
		addLegend(pal = pal, values = legendValues, 
							title = units)
	
	if(!is.null(geoJsonList)){
		for(geJson in geoJsonList){
			addPolygons(leafletProxy(mapName), data=geJson, fill = F ,opacity = 0.7, weight = 2, group = "boundaries")
		}
	}
}


