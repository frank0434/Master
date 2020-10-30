
##' .. content for \description{column wise mean calculation, mm SW will be
##' converted to VWC} 
##'
##' .. content for \details{} ..
##'
##' @title colwise_meanSW
##'
##' @param id.vars 
##' @param col.vars 
##' @param data_SW
##' @import data.table
##'
##' @return
##' @author frank0434
##' @export
colwise_meanSW <- function(data_SW, id.vars = id_vars, col.vars = value_vars){
  
  SW_mean = data_SW[, lapply(.SD, function(x) mean(x, na.rm = TRUE)/100), 
                    by = id.vars,
                    .SDcols = col.vars]
  return(SW_mean)

  
}


#' filter_datemax
#' @description need to know which date has the maximum and minimum SW to figure
#'   out the range from the replicates
#'
#' @param SW_mean 
#'
#' @return
#' @export
#'
#' @examples
filter_datemax <- function(SW_mean, mode = c("max", "min"), id.vars = id_vars){
  if(mode == "max"){
    TEST <- data.table::melt.data.table(SW_mean, id.vars = id.vars, 
                                        variable.name = "Depth", 
                                        variable.factor = FALSE,
                                        value.name = "SW") %>% 
      dplyr::group_by(Experiment, SowingDate, Depth) %>% 
      dplyr::filter(SW == max(SW)) %>% 
      dplyr::group_by(Experiment, SowingDate, Depth, SW) %>% 
      dplyr::filter(Clock.Today == first(Clock.Today))
  } else if(mode == "min"){
    TEST <- data.table::melt.data.table(SW_mean, id.vars = id.vars, 
                                        variable.name = "Depth", 
                                        variable.factor = FALSE,
                                        value.name = "SW") %>% 
      dplyr::group_by(Experiment, SowingDate, Depth) %>% 
      dplyr::filter(SW == min(SW)) %>% 
      dplyr::group_by(Experiment, SowingDate, Depth,SW) %>% 
      dplyr::filter(Clock.Today == first(Clock.Today))
  }

  
  return(TEST)
}

##' .. content for \description{} 
##'
##' .. content for \details{} ..
##'
##' @param SW 
##' @param id.vars 
##' @param value.vars 
##' @param startd 
##' @param endd 
##'
##' @title doDUL_LL_range
##' @return
##' @author frank0434
##' @export
doDUL_LL_range <- function(SW, id.vars = id_vars, 
                           value.vars = value_vars, 
                           startd = "2011-01-01", endd = "2012-06-30") {

  SW <- SW[Clock.Today %between% c(as.Date(startd), as.Date(endd))]
  # should only choose first 5 sowing dates for this 
  SW_mean <- colwise_meanSW(data_SW = SW, id.vars = id.vars, col.vars = value.vars)
  Dates_max <- filter_datemax(SW_mean = SW_mean, id.vars = id.vars, mode = "max")
  Dates_min <- filter_datemax(SW_mean = SW_mean, id.vars = id.vars, mode = "min")

  DT <- data.table::melt.data.table(SW, id.vars = id.vars, 
                                    measure.vars = value.vars,
                                    variable.name = "Depth",
                                    variable.factor = FALSE,
                                    value.name = "SW")[, SW := SW/100]
  
  DT_stats <- DT[, unlist(lapply(.SD, function(x) list(mean=mean(x),
                                                       sd = sd(x),
                                                       n = .N,
                                                       range = list(range(x)))),
                          recursive = FALSE),
                 by = .(Experiment, SowingDate,Depth, Clock.Today), .SDcols = "SW"
                 ][, c("Low", "High") := data.table::tstrsplit(SW.range, split = ",")
                   ][, ':='( Low = as.numeric(gsub("c\\(", "", Low)),
            High = as.numeric(gsub("\\)", "", High)))]
  DUL_range <- DT_stats[setDT(Dates_max), on = c("Experiment", "SowingDate", "Depth", 
                                             "Clock.Today")]
  LL_range <- DT_stats[setDT(Dates_min), on = c("Experiment", "SowingDate", "Depth", 
                                            "Clock.Today")]
  ranges <- merge.data.table(DUL_range, LL_range, 
                             by = c("Experiment", "SowingDate", "Depth"),
                             suffixes = c(".DUL", ".LL"))
  return(ranges)
  
}




#' template_slurp
#'
#' @param outpath 
#' @param template_var 
#' @param template_value 
#'
#' @return
#' @export
#'
#' @examples
#' 

config_slurp <- function(template_var, template_value, outpath){
  # template = readLines("01Data/ApsimxFiles/SlurpBaseConfigTemplate.txt")
  # loadd(SW_DUL_LL)
  # template_value = c(path_AD, 
  #                    390,
  #                    DB_AshleyDene,
  #                    "2010-10-21",
  #                    paste0("2010-10-21", "T00:00:00"),
  #                    file.path(CoverDataDir,paste0("LAI", i, j, ".csv")),
  #                    replacement_initialSW <- SW_DUL_LL[Experiment == i & SowingDate == j]$SW
  #                    replacement_DUL <- SW_DUL_LL[Experiment == i & SowingDate == j]$DUL
  #                    replacement_SAT <- replacement_DUL
  #                    replacement_AirDry <- replacement_LL
  #                    replacement_LL15 <- replacement_LL
  #                    replacement_LL <- SW_DUL_LL[Experiment == i & SowingDate == j]$LL
  #                    replacement_KL <- skl
  #                    )
  
  
}

##' .. content for \description{} (no empty lines) ..
##'
##' .. content for \details{} ..
##'
##' @title

##' @param CoverData 
##'
##' @param output 
##'
##' @return
##' @author frank0434
##' @export
outputCoverData <- function(CoverData, biomass,  
                            output = "Data/ProcessedData/CoverData/"){
  # OUPUT CONFIG

  if(!dir.exists(output)){
    dir.create(output)
  }

  Sites <- unique(CoverData$Experiment)
  SDs <- unique(CoverData$SowingDate)
  # Output observation 
  for(i in Sites){
    for( j in SDs){
      sitesd  <-  biomass[Experiment == i & SowingDate == j]
      
      # Create a Pandas Excel writer using XlsxWriter as the engine.
      write.xlsx(x = sitesd, file = file.path(output, paste0("Observed", i, j, ".xlsx")), 
                 sheet = "Observed")

    }
  }
    
  # Output daily LAI with k
  for(i in Sites){
    for( j in SDs){
      DT <- CoverData[Experiment == i & SowingDate == j
                ][, .(Clock.Today, LAI, k)
                  ][, LAI := ifelse(is.na(LAI) | is.null(LAI), 0, LAI)]
      data.table::fwrite(x = DT, file.path(output, paste0("LAI", i, j, ".csv")))
    }
    }
  
}






##' .. content for \description{} (no empty lines) ..
##'
##' .. content for \details{} ..
##'
##' @title trans_biomass
##' @description only works for Richard Sim's PhD data 

##' @param biomass 
##'
##' @param sowingDates 
##' @param accumTT 
##'
##' @return
##' @author frank0434
##' @export
interp_LAI <- function(biomass, sowingDates, accumTT) {
  
  LAI_Height_SD <- merge.data.table(biomass, sowingDates, 
                                    by = c("Experiment", "Clock.Today" , "SowingDate"), 
                                    all= TRUE)[,
                                               ':='(LAImod = ifelse(is.na(LAImod), 0, LAImod),
                                                    Height = ifelse(is.nan(Height), NA, Height))]
  
  LAI_wide <- dcast.data.table(LAI_Height_SD, 
                               Experiment + Clock.Today ~ SowingDate, 
                               value.var = "LAImod" )

  DT <- merge.data.table(accumTT, LAI_wide, by = c("Experiment", "Clock.Today"), 
                         all.x = TRUE)
  
  DT <- melt.data.table(data = DT, 
                        id.vars = c("Experiment", "Clock.Today", "AccumTT"), 
                        value.name = "LAI",
                        variable.name = "SowingDate", variable.factor = FALSE)
  
  DT[, LAI:= na.approx(LAI, AccumTT, na.rm = FALSE) , by = .(Experiment, SowingDate) ]
  
  DT[, ':='(k = 0.94)
     ][Experiment == "AshleyDene" & Clock.Today %between% c( '2011-11-30','2012-03-01'),
       k:= 0.66][, LI := 1 - exp(-k * LAI) ]
  
  return(DT)
}




##' .. content for \description{} (no empty lines) ..
##'
##' .. content for \details{} ..
##'
##' @title doDUL_LL
##' @description conventional approach to calculate DUL and LL, mean max value
##'   for DUL; mean min values for LL.
##' @import data.table

##' @return
##' @author frank0434
##' @export
doDUL_LL <- function(SW_mean, value_vars) {

  DUL_LL= SW_mean[, unlist(lapply(.SD, max_min), recursive = FALSE), 
                  by = .(Experiment, SowingDate), .SDcols = value_vars]
  # Tidy up DUL AND LL
  melted_DUL_LL = data.table::melt(DUL_LL, 
                                   id.var = c("Experiment","SowingDate"), 
                                   variable.factor = FALSE)
  melted_DUL_LL = melted_DUL_LL[, (c("Depth", "variable")) := tstrsplit(variable, "\\.")
                             ] 
  DUL_LL_SDs = data.table::dcast.data.table(data = melted_DUL_LL, 
                                           Experiment +  SowingDate + Depth ~ variable)
  
  # DUL_LL_SDsVWC = DUL_LL_SDs[, ':='(DUL = round(DUL, digits = 3),
  #                                   LL = round(LL, digits = 3))
  #                            ][, PAWC := DUL - LL]
}



##' .. content for \description{} (no empty lines) ..
##'
##' .. content for \details{} ..
##'
##' @initialSWC
##' @description Join aggregated soil water data with sowing dates to get the
##'   initial soil water content

##' @param DT 
##'
##' @import data.table
##' @return
##' @author frank0434
##' @export
initialSWC <- function(DT, sowingDates, id_vars) {
  SW_initials = SW_mean[sowingDates, 
                        on = c("Experiment", "SowingDate", "Clock.Today"),
                        roll = "nearest"]
  SW_initials_tidied = data.table::melt.data.table(
    SW_initials, 
    id.vars = id_vars, 
    variable.factor = FALSE,
    variable.name = "Depth",
    value.name = "SW"
  )[, ':='(SW = round(SW, digits = 3))]
  
}


#' read_Sims
#'  @description Read Sims PhD data from excel. It tailors to this excel file. 
#'
#' @param path The path to the excel file.
#' @param source A string vector to declare which data source. Default is
#'   `Soil Water`
#'
#' @return a data.table
#' 
#' @import data.table
#'         readxl
#'         inspectdf
#' 
#' @export
#'
#' @examples
read_Sims <- function(path, source = "Soil Water"){
  dt = readxl::read_excel(path, guess_max = 10300, sheet = 2,
                  .name_repair ="universal",
                  skip = 9 ) # fix the names 
  dt = data.table::as.data.table(dt) 
  data.table::setnames(dt, old = c("Site", "Date", "Sowing.Date"), 
                       new = c("Experiment", "Clock.Today", "SowingDate"))
  dt[, ...119 := NULL]
  col_type =  inspectdf::inspect_types(dt)
  col_date = col_type$col_name[[3]]
  dt[, (col_date) := lapply(.SD, function(x) as.Date(x,  tz = "Pacific/Auckland")),
     .SDcol = col_date]
  
  if(source == "Soil Water"){
    SoilWater = dt[Data == "Soil water"]
    
    col_good = choose_cols(SoilWater) # identify the right cols 
    SoilWater <- SoilWater[,..col_good]
    # Fix the colnames here 
    # Fix the layer 
    
    SoilWater[, Data:=NULL 
              ][, SWC.0.2 := NULL] # Drop the second layer
    # New model separate the top 20 cm 
    # Fix the name to match APSIM soil
    swc_vars = grep("SWC", colnames(SoilWater), value = TRUE)
    data.table::setnames(SoilWater, swc_vars[-length(swc_vars)], paste0("SW(", seq(1, 22, 1), ")"))
    data.table::setnames(SoilWater, "SWC.2.3.m..mm.", "SWC")
    return(SoilWater)
  }
  if(source == "sowingDate"){ # need to add a patial match
    sowingDate <- dt[,...120 : I12][!is.na(...120)]
    setnames(sowingDate, "...120", "SowingDate", skip_absent = TRUE)
    SD = sowingDate[, (c("AD", "I12")) := lapply(.SD, as.Date), 
                     .SDcols = c("AD", "I12")] %>% 
      data.table::melt.data.table(id.vars = "SowingDate", 
                       variable.name = "Experiment", value.name = "Clock.Today",
                       variable.factor = FALSE) 
    SD_tidied = SD[, Experiment := ifelse(Experiment == "AD", 
                                          "AshleyDene",  
                                          "Iversen12")]
    return(SD_tidied)
  }
  if(source == "biomass"){
    biomass <- dt[Data == "Biomass"]
    
    col_good <- choose_cols(biomass) # identify the right cols 
    
    biomass <- biomass[,..col_good]
    biomass[, c("...120", "AD", "I12") := NULL]
    return(biomass)
    
  }
  }

#' chop_dates
#'
#' @description Chop a date object into year, yearMonth and monthDay
#' 
#' @param DT a data.table
#' @param col_date a string for the date object column
#'
#' @return
#' @export
#'
#' @examples
chop_dates <- function(DT, col_date = "Date"){
  DT[, ':='(Year = gsub("-\\d{2}-\\d{2}", "", get(col_date)),
            YearMonth = gsub("-\\d{2}$", "", get(col_date)),
            MonthDay = gsub("\\d{4}-", "", get(col_date)))]
  return(DT)
}

#' group_in_season
#' @description  Group annual data into seasonal data 1 July to 30 June next year
#' 
#'
#' @param DT, data.table
#'
#' @return data.table with a column `Season`
#' @export
#'
#' @examples
group_in_season <- function(DT){
  
  stopifnot("Date" %in% colnames(DT))
  
  period <- range(DT$Date)
  noofyear <- diff.Date(period, unit = "year") %>% 
    as.numeric(.)/365
  startyear <- year(period[1])
  endyear <- year(period[2])
  startmd <- "-07-01"
  endmd <- "-06-30"
  noofseason <- round(noofyear, digits = 0)
  
  # Initial a vector to store the text as cmd
  cmd <- vector("character", noofseason)
  
  # Build a cmd to do conditional evaluation 
  
  for(i in 0:(noofseason-1)){
    # Key condition
    v <- paste0("Date >= \"" , startyear + i, startmd,"\"","&",
                "Date <= \"", startyear + i + 1, endmd, "\"",",",
                "\"", startyear +i,"/", startyear + i + 1, "\"",",")
    # Check the format 
    # cat(v)
    # Store it; must be i + 1 since R has no 0 position
    cmd[i + 1] <- v
  }
  # Collapse into one string and glue the fcase function 
  cmd <- paste0("fcase( ", paste(cmd, collapse = ""), ")")
  
  # Delete the end comma
  cmd <- gsub(",)$", ")", cmd)
  # Check format again
  cat("Check if the command format is correct\r\n", cmd)
  
  DT[, Season:= eval(parse(text = cmd))]
  return(DT)
  
  
}



process_bestfit <- function(skl_best_fit, kl_best_fit, saveTo){
  skl_best_fit = skl_best_fit[,.(Experiment, SowingDate, kl = SKL, Depth = 1L)]
  kl_best_fit[,kl := as.numeric(gsub("kl","", kl))]
  kl_best_fit = unique(kl_best_fit[, .(Experiment, SowingDate, Depth, kl)])
  best_fit_layerkl = rbindlist(list(skl_best_fit, kl_best_fit), use.names = TRUE)
  setkey(best_fit_layerkl, Experiment, SowingDate, Depth)
  
}


#' rename_cols
#' @description Rename the soilwater data. The top 20cm data has been
#'   artifically divide into two 10 cm layer. 
#'
#' @param DT data.table which has water data 
#' @param pattern the colnames for soil water content for each layer 
#'
#' @return
#' @export
#'
#' @examples
rename_cols <- function(DT, pattern = "^(?!SW)"){
  if("SWC" %in% names(DT)){
  data.table::setnames(DT, names(DT),  
                       c(grep(pattern = "^(?!SW)" , perl = TRUE, names(DT), value = TRUE), 
                         paste0("SW(", 1:22,")"), 
                         "SWC"))
  } else {
    data.table::setnames(DT, names(DT),  
                         c(grep(pattern = "^(?!SW)" , perl = TRUE, names(DT), value = TRUE), 
                           paste0("SW(", 1:22,")")))
  }
  DT
}
#' max_min
#'
#' @param x 
#'
#' @return
#' @export
#'
#' @examples
max_min <- function(x){list(DUL = max(x, na.rm = TRUE),
                            LL = min(x, na.rm = TRUE))}

#' check_resi
#'
#' @description check if the residue of the simulated and observed values are
#'   randomly placed.
#'
#' @param df
#' @param SimulationID
#' @param col_date
#' @param col_target
#'
#' @return
#' @export
#'
#' @examples
check_resi <-  function(dt, ID = 1L,  col_date = "Clock.Today", col_target ){
  
  print(ID)

  if(is.data.table(dt)){
    cols <- c(col_date, col_target)
    p <- PredObs[SimulationID == as.integer(ID)][, ..cols] %>%
      ggplot(aes_string(col_date, col_target)) +
      geom_point() + 
      theme_water() +
      ggplot2::geom_hline(yintercept = 0, color = "red")
    p
    
  } else{
    print("Only works for data.table format!")
  }

}

#' read_met_col
#'
#' @description read met col names only
#' 
#' @param path 
#' @param skip 
#' @param nrows 
#'
#' @return
#' @export
#'
#' @examples
read_met_col <- function(path = path_met, skip = 7){
  met_col <- data.table::fread(input = path, skip = skip, nrows = 1)
  met_col
}



#' exam_xlsxs
#' 
#' @note need to write unit tests
#' @param path_apX the key path to the file folder
#' @param filename file names
#'
#' @return a data frame
#' @export
#'  
#'
#'
exam_xlsxs <- function(path_apX, filename){
  df = read_excel(file.path(path_apX, filename)) %>% 
    inspect_cat(.) %>% 
    filter(col_name %in% c("Name", "SimulationName")) %>% 
    select(levels) %>% 
    unnest()
  df
}



# fun2 --------------------------------------------------------------------

#' choose_cols
#' @description calculate the number of NAs and nrows, drop the columns are all NAs
#'
#' @param dt a data.table or data.frame
#'
#' @return a vector has colnames for the sepecific table 
#' 
#' @export
#'
#' 
choose_cols <- function(dt){
  logica = sapply(dt, function(x){
    sum(is.na(x)) == dim(dt)[1]
  })
  col_good = names(which(logica != 1))
  col_good
}



# theme -------------------------------------------------------------------

theme_water <- function(){
  theme_classic() + 
    theme(panel.border = element_rect(fill = "NA"),
          text = element_text(size = 14))
}


# fix date ----------------------------------------------------------------

#' Title
#'
#' @param df 
#'
#' @return
#' @export
#' 

fix_date <- function(df, col_Date = "Clock.Today"){
  
  df[[col_Date]] = as.Date(df[[col_Date]])
  dt = data.table::as.data.table(df)
}
