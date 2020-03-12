

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
    filter(col_name == "SimulationName") %>% 
    select(levels) %>% 
    unnest() %>% 
    select(-prop) 
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
  
  dt <- as.data.table(df)
  dt <- dt[, Date := lubridate::dmy(Date)]
  
  dt
}
