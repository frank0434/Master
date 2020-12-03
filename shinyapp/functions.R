#' simulation_query
#'
#' @param pool 
#' @param variable 
#' @param pixel_df 
#' @param factor_inputs 
#' @param discreteValues 
#'
#' @return
#' @export
#'
#' @examples
simulation_query <- function(pool,
                             
                             factor) {
  
  # debug
  # factor_inputs <- meta[Experiment == "Iversen12" & SowingDate == "SD1"] %>% as.list()
  # pool <- poolConnection
  shinyjs::show(id = "loading-page")
  print("Running simulation Query")
  sql <- ""
  simulation_df <- NULL
  tryCatch({
      # sql <- paste0("select simulation_id, pixel_id, ", 
      # 							'"',variable, '", year',
      # 						 ' from "Report" where 1=1')
      sql <- paste0('select * from "Report" where 1=1')
      limitSql <- "and \"%s\" in ('%s')"
      sql <- paste(sql, sprintf(limitSql, "Experiment", factor$Experiment))
      sql <- paste(sql, sprintf(limitSql, "SowingDate", factor$SowingDate))
      
      sql <- paste(sql, sprintf(limitSql, "SKL", factor$SKL))
      sql <- paste(sql, sprintf(limitSql, "KLR", factor$KLR))
      sql <- paste(sql, sprintf(limitSql, "RFV", factor$RFV), ";")
      
      

      cat(sql)
      simulation_df <- pool %>%
        dbGetQuery(sql) %>%
        collect()
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
  return(data.table::as.data.table(simulation_df))
}