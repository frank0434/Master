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


# Plotting ----------------------------------------------------------------

#' linechasedot
#' @description VISUALISE the simulation value as lines and observation value 
#' as dot. 
#'
#' @param DTsims 
#' @param DTobs 
#' @param DUL_LL_range 
#' @param Experiment 
#' @param SowingDate 
#' @param Depth 
#'
#' @return
#' @export
#'
#' @examples
linechasedot <- function(DTsims, DTobs, DUL_LL_range, 
                         Expt, SD, Layer){
  point_size <- 6
  SE1 <- DUL_LL_range[Experiment == Expt & 
                        SowingDate == SD & 
                        Depth == Layer]
  setnames(SE1, "Clock.Today.DUL", "Clock.Today")
  p <- DTsims[,.(Clock.Today, `SWmm(1)`, `DULmm(1)`, `LL15mm(1)`, SKL, KLR, RFV)] %>% 
    ggplot(aes(Clock.Today)) +
    geom_hline(aes(yintercept = `DULmm(1)`), color = "blue") +
    geom_hline(aes(yintercept = `LL15mm(1)`), color = "blue") +
    geom_line(aes(y = `SWmm(1)`), color = "grey",  alpha = 0.5) +
    geom_point(data = DTobs, aes(y = `SW(1)`), color = "red",size = point_size) +
    geom_errorbar(data = SE1, aes(ymin = DUL - SE, ymax = DUL + SE), 
                  show.legend = TRUE, width = 8, size = 1.5) + 
    ggtitle(paste0(Expt, SD)) +
    scale_x_date(date_labels = "%Y %b", date_breaks = "4 weeks") +
    
    # scale_color_manual(name = "", values = palette()) +
    scale_color_manual(name = "", label = c("Simulation", "Observation"), 
                       values = c("grey", "red")) +
    theme_classic() +
    theme(legend.position =  c(.5, .2),
          axis.text = element_text(angle = 30, hjust = 1,size = 14),
          text = element_text(size = 16))
  return(p)
}
