


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
