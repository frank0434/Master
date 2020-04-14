
#' check_resi
#'
#' @description check if the residue of the simulated and observed values are randomly placed. 
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


#' Title
#'
#' @param path 
#' @param skip 
#'
#' @return
#' @export
#'
#' @examples
read_met <- function(path = path_met, skip_unit = 9, skip_meta = 7){
  met_LN <- data.table::fread(input = path,skip = skip_unit, fill = TRUE)
  met_col <- read_met_col(path = path, skip = skip_meta)
  colnames(met_LN) <- colnames(met_col)
  return(met_LN)
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

fix_date <- function(df){
  
  df$Date = as.Date(df$Date)
  dt = data.table::as.data.table(df)
}
