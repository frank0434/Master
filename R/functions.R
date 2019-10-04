


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
