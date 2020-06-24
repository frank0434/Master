


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
#' @description calculate the number of NAs and nrows, select only the unequal numbers 
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
